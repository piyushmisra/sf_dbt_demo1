with source as (
        select * from {{ source('health_app_src', 'meds') }}
  ),
  renamed as (
      select
          {{ adapter.quote("ID") }},
        {{ adapter.quote("MED_NAME") }}

      from source
  )
  select * from renamed
    