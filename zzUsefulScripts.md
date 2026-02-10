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
<!-- drop integration GIT_INTEGRATION; -->
<!-- WAIT: API Integrations need to be created ONLY for 
  GitHub Enterprise Server
  Azure DevOps Server
  Private Git repos that require OAuth or custom auth
 -->
<!-- CREATE OR REPLACE API INTEGRATION git_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/piyushmisra')
  <!-- -- Comment out the following line if your forked repository is public -->
  <!-- ALLOWED_AUTHENTICATION_SECRETS = (tasty_bytes_dbt_db.integrations.tb_dbt_git_secret)
  ENABLED = TRUE; -->

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

<!-- You need Snowflake Git Repository objects and dbt Projects - BOTH are schema‑level objects. -->
<!-- So create a Repo in Snowflake which is connected to the GitHub account as below -->
USE ROLE ACCOUNTADMIN;
USE DATABASE ANALYTICS_DEV;
USE SCHEMA DEV_PIYUSH;

CREATE OR REPLACE GIT REPOSITORY SF_DBT_DEMO1_REPO
  URL = 'https://github.com/piyushmisra/sf_dbt_demo1.git'
  BRANCH = 'main';
  <!-- ......and now link this repo object to Snowflake dbt project -->
ALTER DBT PROJECT SF_DBT_DEMO1
  SET GIT_REPOSITORY = SF_DBT_DEMO1_REPO;



IMPORTANT NOTE: your dbt_project.yml must have 
  profile: snowflake




----------prompt------------------
I want to bring my public dbt repo https://github.com/piyushmisra/sf_dbt_demo1 into trial ver of snowflake https://app.snowflake.com/bvmpgjz/ub87138/#/workspaces/ws/USER%24/PUBLIC/DEFAULT%24/Untitled.sql. follow best practices that enterprise grade pro's use - eg create separate dbt_workspaces.workspace_dev db.schema for dbt project, and analytics_dev for data.
my sf account username passwd is stored in github repo secrets in SNOWFLAKE_USER and SNOWFLAKE_PASSWORD

my current dbt_project.yml is

name: 'sf_dbt_demo1'
version: '1.0.0'

# This setting configures which "profile" dbt uses for this project.
profile: 'snowflake'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

clean-targets:         # directories to be removed by `dbt clean`
  - "target"
  - "dbt_packages"


models:
  sf_dbt_demo1:
    staging:
      health_app:
        +materialized: view
    marts:
      +materialized: table


seeds:
  sf_dbt_demo1:
    +database: RAW
    +schema: HEALTH_APP_SRC

I have only main branch in github. my dbt_packages are checkin the repo from my local. my profile.yml is
snowflake:
  target: prod
  outputs:
    prod:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      database: "{{ env_var('SNOWFLAKE_DB') }}"
      schema: "{{ env_var('SNOWFLAKE_SCHEMA') }}"
      authenticator: "{{ env_var('SNOWFLAKE_AUTHENTICATOR') }}"

  -------------------------------end prompt
create database if not exists DBT_WORKSPACES;
create schema if not exists DBT_WORKSPACES.WORKSPACE_DEV;

create database if not exists RAW;
create schema if not exists RAW.HEALTH_APP_SRC;

create database if not exists ANALYTICS_DEV;
create schema if not exists ANALYTICS_DEV.DEV_PIYUSH;

create database if not exists ANALYTICS_PROD;
create schema if not exists ANALYTICS_PROD.PROD;
----- then for set up of dbt proj creation and git integration:
SET GITHUB_ORIGIN = 'https://github.com/piyushmisra/sf_dbt_demo1.git';
SET GIT_INTEGRATION_NAME = 'GIT_INTEGRATION';
SET GIT_REPO_NAME = 'SF_DBT_DEMO1_REPO';
SET DBT_PROJECT_NAME = 'SF_DBT_DEMO1';

-- Where to store dbt project objects
SET DBT_PROJECT_DB = 'ANALYTICS_DEV';
SET DBT_PROJECT_SCHEMA = 'DBT_PROJECTS';

-- Where to put dbt compiled models/testing
SET DBT_TARGET_DB = 'ANALYTICS_DEV';
SET DBT_TARGET_SCHEMA = 'DEV_PIYUSH';

-- Your user name (for grants)
SET DBT_USER = CURRENT_USER();
-----
CREATE OR REPLACE API INTEGRATION IDENTIFIER($GIT_INTEGRATION_NAME)
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ( $GITHUB_ORIGIN )
  ENABLED = TRUE;

-=-=-=-=-=
CREATE OR REPLACE GIT REPOSITORY DBT_WORKSPACES.WORKSPACE_DEV.SF_DBT_DEMO1_REPO
  API_INTEGRATION = GIT_INTEGRATION
  ORIGIN = 'https://github.com/piyushmisra/sf_dbt_demo1.git';

ALTER GIT REPOSITORY IDENTIFIER($GIT_REPO_NAME) FETCH;


-=-=-=-=-=
CREATE OR REPLACE DBT PROJECT DBT_WORKSPACES.WORKSPACE_DEV.SF_DBT_DEMO1
  FROM '@DBT_WORKSPACES.WORKSPACE_DEV.SF_DBT_DEMO1_REPO/branches/main/'
  QUERY_WAREHOUSE = 'COMPUTE_WH';
ALTER DBT PROJECT
  IDENTIFIER($DBT_PROJECT_DB, $DBT_PROJECT_SCHEMA, $DBT_PROJECT_NAME)
ADD VERSION
FROM '@'
  || IDENTIFIER($DBT_PROJECT_DB, $DBT_PROJECT_SCHEMA, $GIT_REPO_NAME)
  || '/branches/main'
;
EXECUTE DBT PROJECT
  IDENTIFIER($DBT_PROJECT_DB, $DBT_PROJECT_SCHEMA, $DBT_PROJECT_NAME)
  ARGS = 'run --target dev';
----------

USE ROLE ACCOUNTADMIN;
USE DATABASE DBT_WORKSPACES;
USE SCHEMA WORKSPACE_DEV;

-- 1. Refresh the Git Repo to pull your latest 'DUMMY' profile fix
ALTER GIT REPOSITORY SF_DBT_DEMO1_REPO FETCH;

-- 2. Create the Project Object
-- This will work now because the 'DUMMY' values satisfy the parser
CREATE OR REPLACE DBT PROJECT SF_DBT_DEMO1
  FROM '@DBT_WORKSPACES.WORKSPACE_DEV.SF_DBT_DEMO1_REPO/branches/main/';
  QUERY_WAREHOUSE = 'COMPUTE_WH';

------
Versioning workflow

Every time you merge to main in GitHub:

Run:

ALTER GIT REPOSITORY ... FETCH;


Then:

ALTER DBT PROJECT ... ADD VERSION FROM '.../branches/main';


Then run:

EXECUTE DBT PROJECT ... ARGS = 'run --target dev';
