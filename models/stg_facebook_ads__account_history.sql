{{ config(enabled=var('ad_reporting__facebook_ads_enabled', True),
    unique_key = ['source_relation','account_id','_fivetran_synced'],
    partition_by={
      "field": "_fivetran_synced", 
      "data_type": "TIMESTAMP",
      "granularity": "day"
    }
    ) }}

with base as (

    select * 
    from {{ ref('stg_facebook_ads__account_history_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_facebook_ads__account_history_tmp')),
                staging_columns=get_account_history_columns()
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
        cast(id as {{ dbt.type_bigint() }}) as account_id,
        CAST(FORMAT_TIMESTAMP("%F %T", _fivetran_synced, "America/New_York") AS TIMESTAMP) as _fivetran_synced,    --EST Conversion
        name as account_name,
        account_status,
        business_country_code,
        CAST(FORMAT_TIMESTAMP("%F %T", created_time, "America/New_York") AS TIMESTAMP)  as created_at,        --EST Conversion 
        currency,
        timezone_name,
        row_number() over (partition by source_relation, id order by _fivetran_synced desc) = 1 as is_most_recent_record
    from fields

)

select * 
from final
