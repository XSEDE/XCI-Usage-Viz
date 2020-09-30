## XCI Software Usage Metrics Collection Service
## Design and Security Description
##
##  https://docs.google.com/document/d/1l9Ww8OR5QaWC9tqM1mnSfelhzNdZ1Nz972bRw1aLZ1I

##
## Database initialization order
##
1) roles.sql
2) usage_schema.sql

## Database Design
  usage_db database
    usage_schema schema
      usage_owner owner
        std_usage_entry table

## Field length notes:
  USE_CLIENT
    https://stackoverflow.com/questions/32290167/what-is-the-maximum-length-of-a-dns-name
