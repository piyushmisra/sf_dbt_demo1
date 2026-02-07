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


-------------------
** Snowflake setup for GitIntegrations **
Following tutorial at https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-getting-started-tutorial


My workflow is:
  Develop locally in VS Code
  Run dbt deps locally
  Commit dbt_packages/
  Push to GitHub
  Run dbt inside Snowflake (Native dbt)

<!-- No need to create SECRET in SF as my repo is Public -->
<!-- CREATE OR REPLACE SECRET tasty_bytes_dbt_db.integrations.tb_dbt_git_secret
  TYPE = password
  USERNAME = 'your-gh-username'
  PASSWORD = 'YOUR_PERSONAL_ACCESS_TOKEN'; -->

USE ROLE ACCOUNTADMIN;
<!-- The workspace from Github should be imported (created) inside a database - best practice for Prod env -->
CREATE DATABASE DBT_WORKSPACES;
USE DATABASE DBT_WORKSPACES;
CREATE SCHEMA DBT_WORKSPACES.WORKSPACE_DEV;
SHOW INTEGRATIONS;
-- drop integration GIT_INTEGRATION;
CREATE OR REPLACE API INTEGRATION git_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/piyushmisra')
  <!-- -- Comment out the following line if your forked repository is public -->
  <!-- ALLOWED_AUTHENTICATION_SECRETS = (tasty_bytes_dbt_db.integrations.tb_dbt_git_secret) -->
  ENABLED = TRUE;

<!-- You must Create an external access integration in Snowflake for dbt dependencies -->
<!-- WAIT: for Trial accounts, it cannot be done. So just remove gitignore for dbt_packages -->
<!-- To get dependency files from remote URLs, Snowflake needs an external access integration that relies on a network rule. -->
<!-- USE ROLE ACCOUNTADMIN; -->
<!--USE DATABASE ANALYTICS_DEV;   ## eventhough network rules are created at Account level - i.e. outside any db, yet, you need to use a db! -->
<!-- -- Create NETWORK RULE for external access integration -->
<!-- CREATE OR REPLACE NETWORK RULE dbt_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  -- Minimal URL allowlist that is required for dbt deps
  VALUE_LIST = (
    'hub.getdbt.com',
    'codeload.github.com'
    );

-- Create EXTERNAL ACCESS INTEGRATION for dbt access to external dbt package locations

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION dbt_ext_access
  ALLOWED_NETWORK_RULES = (dbt_network_rule)
  ENABLED = TRUE;
 -->

<!-- Import GitHub repo from UI - because the below is not allowed in Trial accounts -->
 <!-- CREATE WORKSPACE JugleBook_workspace
  FROM REPOSITORY = 'https://github.com/piyushmisra/sf_dbt_demo1'
  BRANCH = 'main'
  WAREHOUSE = compute_wh
  COMMENT = 'JungleBook dbt workspace'; -->

IMPORTANT NOTE: your dbt_project.yml must have 
profile: snowflake

