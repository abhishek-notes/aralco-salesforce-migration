#!/usr/bin/env python3
"""
Aralco POS Database Analysis Script
Connects to SQL Server and analyzes the database schema for migration planning
"""

import pyodbc
import pandas as pd
import json
from datetime import datetime
import os

# Database connection parameters
SERVER = 'localhost,1433'
DATABASE = 'AralcoPOS'
USERNAME = 'sa'
PASSWORD = 'YourStrong@Password123'

# Create exports directory if it doesn't exist
os.makedirs('exports/analysis', exist_ok=True)

def get_connection():
    """Establish database connection"""
    try:
        conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'
        conn = pyodbc.connect(conn_str)
        print(f"✅ Connected to {DATABASE} database")
        return conn
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}")
        # Try alternative driver
        try:
            conn_str = f'DRIVER={{SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'
            conn = pyodbc.connect(conn_str)
            print(f"✅ Connected to {DATABASE} database (using SQL Server driver)")
            return conn
        except Exception as e2:
            print(f"❌ Failed with alternative driver: {e2}")
            return None

def analyze_customer_tables(conn):
    """Analyze customer-related tables"""
    print("\n📊 Analyzing Customer Tables...")
    
    customer_query = """
    SELECT TOP 100 
        c.CustomerID,
        c.CustomerNo,
        c.FirstName,
        c.LastName,
        c.CompanyName,
        c.Email,
        c.Phone,
        c.Address1,
        c.City,
        c.ProvinceState,
        c.PostalCode,
        c.Country,
        c.CreditLimit,
        c.AccountBalance,
        c.Points,
        c.LastPurchase,
        c.CreatedDate
    FROM Customer c
    ORDER BY c.CustomerID
    """
    
    try:
        df = pd.read_sql(customer_query, conn)
        df.to_csv('exports/analysis/customer_sample.csv', index=False)
        print(f"✅ Exported {len(df)} customer samples")
        
        # Get customer statistics
        stats_query = """
        SELECT 
            COUNT(*) as TotalCustomers,
            COUNT(DISTINCT Email) as UniqueEmails,
            COUNT(CASE WHEN Email IS NOT NULL AND Email != '' THEN 1 END) as CustomersWithEmail,
            COUNT(CASE WHEN CompanyName IS NOT NULL AND CompanyName != '' THEN 1 END) as BusinessAccounts,
            COUNT(CASE WHEN FirstName IS NOT NULL AND FirstName != '' THEN 1 END) as PersonAccounts,
            AVG(CAST(AccountBalance as FLOAT)) as AvgAccountBalance,
            AVG(CAST(Points as FLOAT)) as AvgPoints
        FROM Customer
        """
        stats = pd.read_sql(stats_query, conn)
        stats.to_csv('exports/analysis/customer_stats.csv', index=False)
        print("✅ Customer statistics exported")
        
    except Exception as e:
        print(f"❌ Error analyzing customers: {e}")

def analyze_product_tables(conn):
    """Analyze product-related tables"""
    print("\n📦 Analyzing Product Tables...")
    
    product_query = """
    SELECT TOP 100
        p.ProductID,
        p.Code,
        p.Description,
        p.ShortDescription,
        p.Category1,
        p.Category2,
        p.Category3,
        p.Department,
        p.Supplier,
        p.Cost,
        p.SellPrice,
        p.OnHand,
        p.Status,
        p.CreatedDate
    FROM Product p
    ORDER BY p.ProductID
    """
    
    try:
        df = pd.read_sql(product_query, conn)
        df.to_csv('exports/analysis/product_sample.csv', index=False)
        print(f"✅ Exported {len(df)} product samples")
        
        # Get product statistics
        stats_query = """
        SELECT 
            COUNT(*) as TotalProducts,
            COUNT(DISTINCT Category1) as UniqueCategory1,
            COUNT(DISTINCT Category2) as UniqueCategory2,
            COUNT(DISTINCT Department) as UniqueDepartments,
            COUNT(DISTINCT Supplier) as UniqueSuppliers,
            AVG(CAST(Cost as FLOAT)) as AvgCost,
            AVG(CAST(SellPrice as FLOAT)) as AvgSellPrice,
            SUM(CAST(OnHand as FLOAT)) as TotalInventory
        FROM Product
        WHERE Status = 'A'
        """
        stats = pd.read_sql(stats_query, conn)
        stats.to_csv('exports/analysis/product_stats.csv', index=False)
        print("✅ Product statistics exported")
        
    except Exception as e:
        print(f"❌ Error analyzing products: {e}")

def analyze_transaction_tables(conn):
    """Analyze transaction-related tables"""
    print("\n💰 Analyzing Transaction Tables...")
    
    trans_query = """
    SELECT TOP 100
        h.POSTransHeadID,
        h.TransNo,
        h.TransDate,
        h.CustomerID,
        h.StoreID,
        h.EmployeeID,
        h.SubTotal,
        h.Tax1,
        h.Tax2,
        h.Total,
        h.TransType,
        h.Status
    FROM POSTransHead h
    WHERE h.TransDate >= DATEADD(month, -6, GETDATE())
    ORDER BY h.TransDate DESC
    """
    
    try:
        df = pd.read_sql(trans_query, conn)
        df.to_csv('exports/analysis/transaction_sample.csv', index=False)
        print(f"✅ Exported {len(df)} transaction samples")
        
        # Get transaction statistics
        stats_query = """
        SELECT 
            COUNT(*) as TotalTransactions,
            COUNT(DISTINCT CustomerID) as UniqueCustomers,
            COUNT(DISTINCT StoreID) as UniqueStores,
            COUNT(DISTINCT CAST(TransDate as DATE)) as TransactionDays,
            MIN(TransDate) as EarliestTransaction,
            MAX(TransDate) as LatestTransaction,
            AVG(CAST(Total as FLOAT)) as AvgTransactionValue,
            SUM(CAST(Total as FLOAT)) as TotalRevenue
        FROM POSTransHead
        WHERE Status = 'C'
        """
        stats = pd.read_sql(stats_query, conn)
        stats.to_csv('exports/analysis/transaction_stats.csv', index=False)
        print("✅ Transaction statistics exported")
        
    except Exception as e:
        print(f"❌ Error analyzing transactions: {e}")

def analyze_relationships(conn):
    """Analyze table relationships"""
    print("\n🔗 Analyzing Table Relationships...")
    
    relationship_query = """
    SELECT 
        fk.name AS FK_Name,
        tp.name AS Parent_Table,
        cp.name AS Parent_Column,
        tr.name AS Referenced_Table,
        cr.name AS Referenced_Column
    FROM sys.foreign_keys fk
    INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
    INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    INNER JOIN sys.columns cp ON fkc.parent_column_id = cp.column_id AND fkc.parent_object_id = cp.object_id
    INNER JOIN sys.columns cr ON fkc.referenced_column_id = cr.column_id AND fkc.referenced_object_id = cr.object_id
    ORDER BY tp.name, fk.name
    """
    
    try:
        df = pd.read_sql(relationship_query, conn)
        if len(df) > 0:
            df.to_csv('exports/analysis/table_relationships.csv', index=False)
            print(f"✅ Exported {len(df)} relationships")
        else:
            print("⚠️  No foreign key relationships found (database may use application-level relationships)")
    except Exception as e:
        print(f"❌ Error analyzing relationships: {e}")

def generate_summary_report(conn):
    """Generate comprehensive summary report"""
    print("\n📋 Generating Summary Report...")
    
    summary = {
        "analysis_date": datetime.now().isoformat(),
        "database": DATABASE,
        "findings": {}
    }
    
    # Table counts
    table_count_query = """
    SELECT 
        t.name as TableName,
        p.rows as RecordCount
    FROM sys.tables t
    INNER JOIN sys.partitions p ON t.object_id = p.object_id
    WHERE p.index_id IN (0, 1)
    ORDER BY p.rows DESC
    """
    
    try:
        df = pd.read_sql(table_count_query, conn)
        summary["findings"]["total_tables"] = len(df)
        summary["findings"]["top_10_tables"] = df.head(10).to_dict('records')
        
        with open('exports/analysis/database_summary.json', 'w') as f:
            json.dump(summary, f, indent=2)
        print("✅ Summary report generated")
        
    except Exception as e:
        print(f"❌ Error generating summary: {e}")

def main():
    """Main analysis function"""
    print("🚀 Starting Aralco POS Database Analysis...")
    
    conn = get_connection()
    if not conn:
        print("❌ Cannot proceed without database connection")
        return
    
    try:
        analyze_customer_tables(conn)
        analyze_product_tables(conn)
        analyze_transaction_tables(conn)
        analyze_relationships(conn)
        generate_summary_report(conn)
        
        print("\n✅ Analysis complete! Check exports/analysis/ directory for results.")
        
    finally:
        conn.close()
        print("🔒 Database connection closed")

if __name__ == "__main__":
    main()