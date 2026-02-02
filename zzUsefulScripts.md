For generating code automatically:

https://hub.getdbt.com/dbt-labs/codegen/latest/ - look at other codegen packages to see to generate files like _src_xxxxxx.yml  - that is for dbt Cloud and (probably) for Snowflake dbt workspace UI

For dbt core, do

dbt clean
dbt seed
dbt deps
dbt compile
dbt run-operation generate_source `
  --args '{
    schema_name: "health_app_src",
    database_name: "raw",
    generate_columns: true,
##    include_tables: ["meds","patients","prescriptions"],  ## optional
##    loaded_at_field: "created_at"
  }'
