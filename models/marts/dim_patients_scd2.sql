{{ config(
    materialized = 'incremental',
    incremental_strategy = 'delete+insert',
    unique_key = 'natural_key'
) }}

-- 1. Source snapshot
with source as (
    select
        id as natural_key,
        first_name,
        last_name,
        abs(hash(id, first_name, last_name)) as scd_hash,
        current_timestamp() as load_ts
    from {{ ref('stg_seed__patients') }}
)

{% if is_incremental() %}

-- 2. Existing history (already has patient_sk)
, existing as (
    select *
    from {{ this }}
)

-- 3. Keys that changed or are new
, changed_keys as (
    select
        s.natural_key
    from source s
    left join existing e
        on s.natural_key = e.natural_key
       and e.is_current = true
    where e.natural_key is null
       or s.scd_hash != e.scd_hash
)

-- 4. History that stays unchanged (keep existing patient_sk)
, history_unchanged as (
    select
        e.patient_sk,
        e.natural_key,
        e.first_name,
        e.last_name,
        e.scd_hash,
        e.valid_from,
        e.valid_to,
        e.is_current
    from existing e
    left join changed_keys ck
        on e.natural_key = ck.natural_key
    where ck.natural_key is null
)

-- 5. Expire all current rows for changed keys (keep same patient_sk)
, history_expired as (
    select
        e.patient_sk,
        e.natural_key,
        e.first_name,
        e.last_name,
        e.scd_hash,
        e.valid_from,
        current_timestamp() as valid_to,
        false as is_current
    from existing e
    join changed_keys ck
        on e.natural_key = ck.natural_key
    where e.is_current = true
)

-- 6. Insert new current rows (generate new patient_sk)
, history_new as (
    select
        abs(hash(s.natural_key, current_timestamp())) as patient_sk,
        s.natural_key,
        s.first_name,
        s.last_name,
        s.scd_hash,
        current_timestamp() as valid_from,
        null as valid_to,
        true as is_current
    from source s
    join changed_keys ck
        on s.natural_key = ck.natural_key
)

{% else %}

-- FIRST RUN: explicit schema for all branches (8 columns)

, history_unchanged as (
    select
        abs(hash(id, current_timestamp())) as patient_sk,
        id as natural_key,
        first_name,
        last_name,
        abs(hash(id, first_name, last_name)) as scd_hash,
        current_timestamp() as valid_from,
        null as valid_to,
        true as is_current
    from {{ ref('stg_seed__patients') }}
)

, history_expired as (
    select
        cast(null as number)   as patient_sk,
        cast(null as number)   as natural_key,
        cast(null as string)   as first_name,
        cast(null as string)   as last_name,
        cast(null as number)   as scd_hash,
        cast(null as timestamp) as valid_from,
        cast(null as timestamp) as valid_to,
        cast(null as boolean)  as is_current
    where 1=0
)

, history_new as (
    select
        cast(null as number)   as patient_sk,
        cast(null as number)   as natural_key,
        cast(null as string)   as first_name,
        cast(null as string)   as last_name,
        cast(null as number)   as scd_hash,
        cast(null as timestamp) as valid_from,
        cast(null as timestamp) as valid_to,
        cast(null as boolean)  as is_current
    where 1=0
)

{% endif %}

-- 7. Final SCD2 output
select
    patient_sk,
    natural_key,
    first_name,
    last_name,
    scd_hash,
    valid_from,
    valid_to,
    is_current
from (
    select * from history_unchanged
    union all
    select * from history_expired
    union all
    select * from history_new
)
