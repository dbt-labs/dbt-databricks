{% macro get_alter_materialized_view_as_sql(
    relation,
    configuration_changes,
    sql,
    existing_relation,
    backup_relation,
    intermediate_relation
) %}
    {{- log('Applying ALTER to: ' ~ relation) -}}
    {%- do return(adapter.dispatch('get_alter_materialized_view_as_sql', 'dbt')(
        relation,
        configuration_changes,
        sql,
        existing_relation,
        backup_relation,
        intermediate_relation
    )) -%}
{% endmacro %}

{% macro databricks__get_alter_materialized_view_as_sql(
    relation,
    configuration_changes,
    sql,
    existing_relation,
    backup_relation,
    intermediate_relation
) %}
    -- apply a full refresh immediately if needed
    {% if configuration_changes.requires_full_refresh %}
        {% do return(get_replace_sql(existing_relation, relation,  sql)) %}

    -- otherwise apply individual changes as needed
    {% else %}
        {% do return(get_alter_mv_internal(relation, configuration_changes)) %}
    {%- endif -%}
{% endmacro %}

{% macro get_alter_mv_internal(relation, configuration_changes) %}
    {%- set refresh = configuration_changes.changes["refresh"] -%}
    -- Currently only schedule can be altered
    ALTER MATERIALIZED VIEW {{ relation.render() }}
        {{ get_alter_sql_refresh_schedule(refresh.cron, refresh.time_zone_value, refresh.is_altered) -}}
{% endmacro %}
