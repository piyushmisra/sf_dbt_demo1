{{ config(
    materialized = 'incremental',
    unique_key = 'natural_key',
    incremental_strategy = 'merge',
    merge_update_columns = ['valid_to', 'is_current']
) }}

with source as (
    select
        id,
        first_name,
        last_name,
        {{ dbt_utils.generate_surrogate_key(['id']) }} as natural_key,
        {{ dbt_utils.generate_surrogate_key(['id','first_name','last_name']) }} as scd_hash,
        current_timestamp() as updated_at
    from {{ ref('stg_seed__patients') }}
),

{% if is_incremental() %}
current_target as (
    select *
    from {{ this }}
    where is_current = true
),

records_to_insert as (
    select
        s.id,
        s.first_name,
        s.last_name,
        s.natural_key,
        s.scd_hash,
        current_timestamp() as valid_from,
        null as valid_to,
        true as is_current
    from source s
    left join current_target t
        on s.natural_key = t.natural_key
    where t.natural_key is null
       or s.scd_hash != t.scd_hash
)
{% else %}
records_to_insert as (
    select
        id,
        first_name,
        last_name,
        natural_key,
        scd_hash,
        current_timestamp() as valid_from,
        null as valid_to,
        true as is_current
    from source
)
{% endif %}

select
    {{ dbt_utils.generate_surrogate_key(['natural_key','valid_from']) }} as patient_sk,
    *
from records_to_insert
