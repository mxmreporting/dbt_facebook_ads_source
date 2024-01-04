{{ config(enabled=var('ad_reporting__facebook_ads_enabled', True),
    unique_key = ['source_relation','campaign_id','updated_at'],
    partition_by={
      "field": "updated_at", 
      "data_type": "TIMESTAMP",
      "granularity": "day"
    }
    ) }}

with base as (

    select * 
    from {{ ref('stg_facebook_ads__campaign_history_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_facebook_ads__campaign_history_tmp')),
                staging_columns=get_campaign_history_columns()
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
        CAST(FORMAT_TIMESTAMP("%F %T", updated_time, "America/New_York") AS TIMESTAMP) as  updated_at,    --EST Conversion 
        CAST(FORMAT_TIMESTAMP("%F %T", created_time, "America/New_York") AS TIMESTAMP) as created_at,        --EST Conversion 
        cast(account_id as {{ dbt.type_bigint() }}) as account_id,
        cast(id as {{ dbt.type_bigint() }}) as campaign_id,
        name as campaign_name,
        CAST(FORMAT_TIMESTAMP("%F %T", start_time, "America/New_York") AS TIMESTAMP) as start_at,    --EST Conversion
        CAST(FORMAT_TIMESTAMP("%F %T", stop_time, "America/New_York") AS TIMESTAMP) as end_at,        --EST Conversion 
        status,
        daily_budget,
        lifetime_budget,
        budget_remaining,
        row_number() over (partition by source_relation, id order by updated_time desc) = 1 as is_most_recent_record
    from fields

)

select * 
from final
