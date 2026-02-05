{{ config(materialized = 'view') }}

select
    patient_sk,
    natural_key,
    first_name,
    last_name,
    scd_hash,
    valid_from,
    valid_to,
    is_current
from {{ ref('dim_patients_scd2') }}
