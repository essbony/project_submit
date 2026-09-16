# D .open my_db.duckdb
  INSTALL spatial;
 LOAD spatial;

 - CREATE OR REPLACE TABLE raw_campaign_spend_export AS
  SELECT * FROM st_read('dataset.xlsx', layer="campaign_spend_export");

 - CREATE OR REPLACE TABLE raw_pos_sales_daily AS
  SELECT * FROM st_read('dataset.xlsx', layer="pos_sales_daily");

 - CREATE OR REPLACE TABLE raw_social_comments AS
    SELECT * FROM st_read('dataset.xlsx', layer="social_comments");

 - CREATE OR REPLACE TABLE raw_whatsapp_orders AS
    SELECT * FROM st_read('dataset.xlsx', layer="whatsapp_orders");

 - CREATE OR REPLACE TABLE raw_media_plan AS
    SELECT * FROM st_read('dataset.xlsx', layer="media_plan");

 - SHOW TABLES -- 

 - SELECT * 
  FROM raw_pos_sales_daily LIMIT 5;

## - SUMMARIZE raw_pos_sales_daily;

## - .quit
## - dbt --version
## - dbt init project_submit

##  - profiles.yml puis les chemins du fichier .duckdb
##  cd project_submit  &&  dbt debug
## creer packages.yml puis dbt deps