{% macro generate_stg_models_for_seeds(
    source_name,
    schema_name,
    prefix='stg_seed__'
) %}

{% set relations = dbt_utils.get_relations_by_pattern(
    schema_pattern=schema_name,
    table_pattern='%',
    database=target.database
) %}

{% for rel in relations %}
    {% set model_name = prefix ~ rel.identifier %}

-- ===============================
-- {{ model_name }}.sql
-- ===============================

{{ codegen.generate_base_model(
    source_name=source_name,
    table_name=rel.identifier
) }}

{% endfor %}

{% endmacro %}
