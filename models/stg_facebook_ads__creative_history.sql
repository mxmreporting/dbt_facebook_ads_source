{{ config(enabled=var('ad_reporting__facebook_ads_enabled', True),
    unique_key = ['source_relation','creative_id','_fivetran_synced'],
    partition_by={
      "field": "_fivetran_synced", 
      "data_type": "TIMESTAMP",
      "granularity": "day"
    }
    ) }}

with base as (

    select * 
    from {{ ref('stg_facebook_ads__creative_history_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_facebook_ads__creative_history_tmp')),
                staging_columns=get_creative_history_columns()
            )
        }}
        
    
        {{ fivetran_utils.source_relation(
            union_schema_variable='facebook_ads_union_schemas', 
            union_database_variable='facebook_ads_union_databases') 
        }}

    from base
),

final as (

    select
        source_relation, 
        _fivetran_id,
        CAST(FORMAT_TIMESTAMP("%F %T", _fivetran_synced, "America/New_York") AS TIMESTAMP) as _fivetran_synced,        --EST Converison
        cast(id as {{ dbt.type_bigint() }}) as creative_id,
        cast(account_id as {{ dbt.type_bigint() }}) as account_id,
        name as creative_name,
        page_link,
        template_page_link,
        url_tags,
        asset_feed_spec_link_urls,
        object_story_link_data_child_attachments,
        object_story_link_data_caption, 
        object_story_link_data_description, 
        object_story_link_data_link, 
        object_story_link_data_message,
        template_app_link_spec_ios,
        template_app_link_spec_ipad,
        template_app_link_spec_android,
        template_app_link_spec_iphone,
        row_number() over (partition by source_relation, id order by _fivetran_synced desc) = 1 as is_most_recent_record
    from fields
)

select * 
from final
