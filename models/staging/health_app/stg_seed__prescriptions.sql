with source as (
        select * from {{ source('health_app_src', 'prescriptions') }}
  ),
  renamed as (
      select
          {{ adapter.quote("MED_ID") }},
        {{ adapter.quote("PATIENT_ID") }},
        {{ adapter.quote("DOSAGE") }},
        {{ adapter.quote("FREQUENCY") }},
        {{ adapter.quote("DATE_PRESCRIBED") }},
        {{ adapter.quote("FIRST_DOSAGE_DATE") }},
        {{ adapter.quote("END_DOSAGE_DATE") }}

      from source
  )
  select * from renamed
    