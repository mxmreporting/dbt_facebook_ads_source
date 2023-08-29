{{ config(enabled=var('ad_reporting__facebook_ads_enabled', True)) }}

{{
    fivetran_utils.union_data(
        table_identifier='ad_history', 
        database_variable='facebook_ads_database', 
        schema_variable='facebook_ads_schema', 
        default_database=target.database,
        default_schema='facebook_ads',
        default_variable='ad_history_source',
        union_schema_variable='facebook_ads_union_schemas',
        union_database_variable='facebook_ads_union_databases'
    )
}}