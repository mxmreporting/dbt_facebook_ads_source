{{ config(enabled=var('ad_reporting__facebook_ads_enabled', True),
     unique_key = ['source_relation','date_day','ad_id','account_id'],
    partition_by={
      "field": "date_day", 
      "data_type": "date",
      "granularity": "day"
    }
    ) }}

with base as (

    select * 
    from {{ ref('stg_facebook_ads__basic_ad_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_facebook_ads__basic_ad_tmp')),
                staging_columns=get_basic_ad_columns()
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
        cast(ad_id as {{ dbt.type_bigint() }}) as ad_id,
        ad_name,
        adset_name as ad_set_name,
        DATE(TIMESTAMP(date, "America/New_York")) AS date_day,     --EST timezone conversion
        cast(account_id as {{ dbt.type_bigint() }}) as account_id,
        impressions,
        coalesce(inline_link_clicks,0) as clicks,
        spend,
        reach,
        frequency

        {{ fivetran_utils.fill_pass_through_columns('facebook_ads__basic_ad_passthrough_metrics') }}
    from fields
)

select * 
from final
where DATE(date_day) >= DATE_ADD(CURRENT_DATE(), INTERVAL -2 YEAR)
