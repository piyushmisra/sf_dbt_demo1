with source as (
        select * from {{ source('health_app_src', 'patients') }}
  ),
  renamed as (
      select
          {{ adapter.quote("ID") }},
        {{ adapter.quote("FIRST_NAME") }},
        {{ adapter.quote("LAST_NAME") }}

      from source
  )
  select * from renamed
    