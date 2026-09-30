# SQL Window Functions Intro (AdventureWorks 2022)

Veda Technology Internship - Data Analytics Track

## Objective
Use ROW_NUMBER, RANK, DENSE_RANK and LAG to answer business questions (ranking, top-N per group, month-over-month and year-over-year trends).

## Dataset
AdventureWorks 2022 (denormalized): 57,851 order lines, Jul 2017 - May 2020.
The raw file is pipe (`|`) delimited with `$` in money columns, so `prepare_data.py` converts it into `data/adventureworks_clean.csv`.

## Tools
SQL (PostgreSQL + pgAdmin), Python (pandas) for data cleaning, reportlab/matplotlib for the report.

## Folder structure
```
data/adventureworks_clean.csv        cleaned dataset
prepare_data.py                      raw -> clean CSV
window_functions_queries.sql         table setup + 12 queries (PostgreSQL)
outputs/q01_output.csv ... q12       query outputs
outputs/chart_*.png                  charts
SQL_Window_Functions_Report.pdf      project report
```

## How to run
1. Create a database in pgAdmin, open Query Tool and run the "TABLE SETUP" part of `window_functions_queries.sql`.
2. Right-click table `sales` > Import/Export Data > Import, pick `data/adventureworks_clean.csv`, Header = ON, Delimiter = `,`.
3. Run each query (Q1 to Q12) one by one.

## The 12 queries
| # | Function | Question |
|---|----------|----------|
| 1 | ROW_NUMBER | Number line items within each order |
| 2 | ROW_NUMBER | Most recent order per reseller |
| 3 | ROW_NUMBER | Top 3 products per territory region |
| 4 | RANK | Rank salespeople by total sales |
| 5 | RANK + PARTITION BY | Top 3 salespeople per territory group |
| 6 | ROW_NUMBER vs RANK vs DENSE_RANK | Tie behaviour on units sold |
| 7 | DENSE_RANK | Top 2 resellers per country |
| 8 | LAG | Monthly sales vs previous month |
| 9 | LAG | Month-over-month growth % |
| 10 | LAG + PARTITION BY | Year-over-year growth per territory group |
| 11 | LAG | Days between a reseller's consecutive orders |
| 12 | SUM() OVER + LAG | Year-to-date running total, Up/Down vs previous month |

## Key findings
- Linda Mitchell, Jillian Carson and Michael Blythe are the top 3 salespeople.
- Sales drop every January and recover in February.
- Most resellers reorder roughly every 90 days.
- 2017 (Jul-Dec) and 2020 (Jan-May) are partial years, so YoY for those years is not a true decline/growth.

## Interview answers
- **RANK vs DENSE_RANK:** on ties both give the same rank, but RANK skips the next number (1,2,2,4) and DENSE_RANK does not (1,2,2,3).
- **When to use LAG:** to compare a row with the previous row in the same partition, e.g. MoM/YoY growth or gaps between events.
