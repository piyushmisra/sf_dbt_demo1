{{ config(
    materialized = 'incremental',
    unique_key = 'natural_key',
    incremental_strategy = 'merge',
    merge_update_columns = ['valid_to', 'is_current']
) }}

with source as (
    select
        id as natural_key,
        first_name,
        last_name,
        abs(hash(id, first_name, last_name)) as scd_hash,
        current_timestamp() as updated_at
    from {{ ref('stg_seed__patients') }}
)

{% if is_incremental() %}
, current_target as (
    select *
    from {{ this }}
    where is_current = true
)

, rows_to_expire as (
    select
        t.natural_key,
        t.first_name,
        t.last_name,
        t.scd_hash,
        t.valid_from,
        current_timestamp() as valid_to,
        false as is_current
    from current_target t
    join source s
        on s.natural_key = t.natural_key
    where s.scd_hash != t.scd_hash
)
{% endif %}

, new_rows as (
    select
        s.natural_key,
        s.first_name,
        s.last_name,
        s.scd_hash,
        current_timestamp() as valid_from,
        null as valid_to,
        true as is_current
    from source s
    {% if is_incremental() %}
    left join current_target t
        on s.natural_key = t.natural_key
    where t.natural_key is null
       or s.scd_hash != t.scd_hash
    {% endif %}
)

select
    abs(hash(natural_key, valid_from)) as patient_sk,
    natural_key,
    first_name,
    last_name,
    scd_hash,
    valid_from,
    valid_to,
    is_current
from (
    {% if is_incremental() %}
    select * from rows_to_expire
    union all
    {% endif %}
    select * from new_rows
)
