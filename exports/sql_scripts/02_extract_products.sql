-- ============================================
-- Aralco to Salesforce Migration
-- Product Data Extraction Script
-- ============================================
-- This script extracts product data from Aralco POS
-- and prepares it for Salesforce Product2 import
-- ============================================

USE AralcoPOS;
GO

-- Main Product Extraction
SELECT 
    p.ProductID as Aralco_Product_ID__c,
    p.Code as ProductCode,
    LEFT(p.Description, 255) as Name, -- Salesforce limit is 255 chars
    p.ShortDescription as Description,
    p.Category1 as Family,
    p.Category2 as Product_Category_2__c,
    p.Category3 as Product_Category_3__c,
    p.Department as Department__c,
    p.Cost as Cost__c,
    p.SellPrice as List_Price__c,
    p.OnHand as Quantity_On_Hand__c,
    CASE 
        WHEN p.Status = 'A' THEN 'true' 
        ELSE 'false' 
    END as IsActive,
    p.Weight as Weight__c,
    p.Volume as Volume__c,
    p.Supplier as Supplier_Code__c,
    p.Brand as Brand__c,
    p.Model as Model__c,
    p.Color as Color__c,
    p.Size as Size__c,
    p.UPC as UPC__c,
    p.MinQty as Minimum_Quantity__c,
    p.MaxQty as Maximum_Quantity__c,
    p.ReorderPoint as Reorder_Point__c,
    p.ReorderQty as Reorder_Quantity__c,
    p.LeadTime as Lead_Time_Days__c,
    p.CreatedDate as Aralco_Created_Date__c,
    p.LastUpdate as LastModifiedDate,
    p.Notes as Internal_Notes__c,
    CASE 
        WHEN p.Taxable1 = 1 THEN 'true' 
        ELSE 'false' 
    END as Taxable__c,
    CASE 
        WHEN p.Discountable = 1 THEN 'true' 
        ELSE 'false' 
    END as Discountable__c,
    CASE 
        WHEN p.WebItem = 1 THEN 'true' 
        ELSE 'false' 
    END as Available_Online__c
INTO #ProductExport
FROM Product p;

-- Export Product Categories for Picklist Values
SELECT DISTINCT Category1 as ProductFamily
FROM Product 
WHERE Category1 IS NOT NULL AND Category1 != ''
ORDER BY Category1;

-- Export Departments for Reference
SELECT DISTINCT Department
FROM Product 
WHERE Department IS NOT NULL AND Department != ''
ORDER BY Department;

-- Export Suppliers for Account Mapping
SELECT DISTINCT 
    p.Supplier as SupplierCode,
    s.Name as SupplierName,
    s.SupplierID
FROM Product p
LEFT JOIN Supplier s ON p.Supplier = s.Code
WHERE p.Supplier IS NOT NULL AND p.Supplier != ''
ORDER BY p.Supplier;

-- Create Price Book Entry Data
SELECT 
    p.Aralco_Product_ID__c,
    p.ProductCode,
    p.Name as ProductName,
    'Standard Price Book' as Pricebook2Name,
    p.List_Price__c as UnitPrice,
    'true' as IsActive,
    'USD' as CurrencyIsoCode
FROM #ProductExport p
WHERE p.IsActive = 'true';

-- Product Inventory by Store
SELECT 
    i.ProductID as Aralco_Product_ID__c,
    i.StoreID as Store_ID__c,
    i.OnHand as Quantity_On_Hand__c,
    i.Available as Available_Quantity__c,
    i.OnOrder as On_Order__c,
    i.MinQty as Store_Min_Qty__c,
    i.MaxQty as Store_Max_Qty__c,
    i.LastReceived as Last_Received_Date__c,
    i.LastSold as Last_Sold_Date__c
FROM Inventory i
INNER JOIN Product p ON i.ProductID = p.ProductID
WHERE p.Status = 'A';

-- Data Quality Report
PRINT '=== Product Data Quality Report ==='
PRINT ''

SELECT 
    'Total Products' as Metric,
    COUNT(*) as Count
FROM Product
UNION ALL
SELECT 
    'Active Products',
    COUNT(*) 
FROM Product 
WHERE Status = 'A'
UNION ALL
SELECT 
    'Products with Description',
    COUNT(*) 
FROM Product 
WHERE Description IS NOT NULL AND Description != ''
UNION ALL
SELECT 
    'Products with Cost',
    COUNT(*) 
FROM Product 
WHERE Cost IS NOT NULL AND Cost > 0
UNION ALL
SELECT 
    'Products with Price',
    COUNT(*) 
FROM Product 
WHERE SellPrice IS NOT NULL AND SellPrice > 0
UNION ALL
SELECT 
    'Products with Inventory',
    COUNT(*) 
FROM Product 
WHERE OnHand IS NOT NULL AND OnHand > 0
UNION ALL
SELECT 
    'Web-Enabled Products',
    COUNT(*) 
FROM Product 
WHERE WebItem = 1;

-- Final Export
SELECT * FROM #ProductExport
ORDER BY ProductCode;

-- Cleanup
DROP TABLE #ProductExport;