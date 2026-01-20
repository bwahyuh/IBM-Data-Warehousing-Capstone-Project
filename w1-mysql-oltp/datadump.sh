#!/bin/bash

# MySQL credentials
DB_USER="root"
DB_NAME="sales"
TABLE_NAME="sales_data"
OUTPUT_FILE="sales_data.sql"

# Export data
mysqldump -u "$DB_USER" -p "$DB_NAME" "$TABLE_NAME" > "$OUTPUT_FILE"

# Check if the export was successful
if [ $? -eq 0 ]; then
    echo "Export successful! Data saved to $OUTPUT_FILE"
else
    echo "Export failed!"
fi