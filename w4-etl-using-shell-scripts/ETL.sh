#!/bin/sh

# Set MySQL and PostgreSQL credentials
MYSQL_USER="root"
MYSQL_PASSWORD="<Replace with your mysqls password>"
MYSQL_DB="sales"
MYSQL_HOST="mysql"
MYSQL_PORT="3306"

PG_USER="postgres"
PG_PASSWORD="<Replace with your postgres password>"
PG_DB="sales_new"
PG_HOST="postgres"

# Extract new data from MySQL (last 4 hours) and store it in a CSV
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DB --execute="
SELECT rowid, product_id, customer_id, price, quantity, timestamp
FROM sales_data
WHERE timestamp >= NOW() - INTERVAL 4 HOUR;" --batch --silent > /home/project/sales.csv

# Convert tab-separated values to comma-separated values
tr '\t' ',' < /home/project/sales.csv > /home/project/temp_sales_commas.csv
mv /home/project/temp_sales_commas.csv /home/project/sales.csv

# Load extracted data into PostgreSQL (sales_data table)
export PGPASSWORD=$PG_PASSWORD
psql --username=$PG_USER --host=$PG_HOST --dbname=$PG_DB -c "\COPY sales_data(rowid, product_id, customer_id, price, quantity, timestamp) FROM '/home/project/sales.csv' DELIMITER ',' CSV;"

# Remove sales.csv after loading
rm -f /home/project/sales.csv

# Load transformed data into DimDate table (Avoid duplicates)
psql --username=$PG_USER --host=$PG_HOST --dbname=$PG_DB -c "
INSERT INTO DimDate(dateid, day, month, year)
SELECT DISTINCT EXTRACT(DAY FROM timestamp) AS dateid, 
       TO_CHAR(timestamp, 'Day') AS day, 
       TO_CHAR(timestamp, 'Month') AS month, 
       TO_CHAR(timestamp, 'YYYY') AS year
FROM sales_data
WHERE NOT EXISTS (
    SELECT 1 FROM DimDate d WHERE d.dateid = EXTRACT(DAY FROM sales_data.timestamp)
);
"

# Load transformed data into FactSales table
psql --username=$PG_USER --host=$PG_HOST --dbname=$PG_DB -c "
INSERT INTO FactSales(rowid, product_id, customer_id, price, total_price)
SELECT rowid, product_id, customer_id, price, price * quantity AS total_price
FROM sales_data;
"

# Export DimDate table to CSV
psql --username=$PG_USER --host=$PG_HOST --dbname=$PG_DB -c "\COPY DimDate TO '/home/project/DimDate.csv' DELIMITER ',' CSV HEADER;"

# Export FactSales table to CSV
psql --username=$PG_USER --host=$PG_HOST --dbname=$PG_DB -c "\COPY FactSales TO '/home/project/FactSales.csv' DELIMITER ',' CSV HEADER;"

echo "ETL process completed successfully."
