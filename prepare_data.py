"""Raw AdventureWorks CSV (pipe-delimited, '$' in money columns) ko clean, comma-separated CSV me badalta hai."""
import pandas as pd

RAW = "adventureworks_2022_denormalized.csv"
OUT = "data/adventureworks_clean.csv"

df = pd.read_csv(RAW, sep="|")

def money(s):
    return s.astype(str).str.replace(r"[$,]", "", regex=True).astype(float)

clean = pd.DataFrame({
    "sales_order_number": df["sales_order_number"],
    "order_date": pd.to_datetime(df["sales_order_date"], format="%A, %B %d, %Y").dt.strftime("%Y-%m-%d"),
    "quantity": df["quantity"],
    "unit_price": money(df["unit_price"]),
    "total_sales": money(df["total_sales"]),
    "cost": money(df["cost"]),
    "product_name": df["product_name"],
    "reseller_name": df["reseller_name"],
    "reseller_country": df["reseller_country"],
    "salesperson_fullname": df["salesperson_fullname"],
    "sales_territory_region": df["sales_territory_region"],
    "sales_territory_group": df["sales_territory_group"],
})
clean.to_csv(OUT, index=False)
print(clean.shape)
print(clean.head())
