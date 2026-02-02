{% macro generate_schema_name(custom_schema_name, node) %}
    {# 
      If a custom schema is provided (like HEALTH_APP), 
      use it exactly as-is. 
      Otherwise fall back to the profile schema.
    #}

    {% if custom_schema_name is not none %}
        {{ custom_schema_name | upper }}
    {% else %}
        {{ target.schema }}
    {% endif %}
{% endmacro %}
