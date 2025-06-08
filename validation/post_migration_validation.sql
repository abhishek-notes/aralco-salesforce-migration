-- ============================================
-- Post-Migration Validation Queries
-- ============================================
-- Run these queries against Aralco POS to validate
-- data integrity after Salesforce migration
-- ============================================

USE AralcoPOS;
GO

-- ============================================
-- 1. CUSTOMER VALIDATION
-- ============================================
PRINT '=== CUSTOMER VALIDATION ==='
PRINT ''

-- Total customer count
SELECT 'Total Customers in Aralco' as Metric, COUNT(*) as Count
FROM Customer;

-- Active customers
SELECT 'Active Customers' as Metric, COUNT(*) as Count
FROM Customer
WHERE Deactivate != 1 OR Deactivate IS NULL;

-- Customers by type
SELECT 
    CASE 
        WHEN CompanyName IS NOT NULL AND CompanyName != '' 
             AND (FirstName IS NULL OR FirstName = '') 
             AND (LastName IS NULL OR LastName = '') THEN 'Business Account'
        ELSE 'Person Account'
    END as AccountType,
    COUNT(*) as Count
FROM Customer
GROUP BY 
    CASE 
        WHEN CompanyName IS NOT NULL AND CompanyName != '' 
             AND (FirstName IS NULL OR FirstName = '') 
             AND (LastName IS NULL OR LastName = '') THEN 'Business Account'
        ELSE 'Person Account'
    END;

-- Customers with missing critical data
SELECT 'Customers Missing Email' as Issue, COUNT(*) as Count
FROM Customer WHERE Email IS NULL OR Email = ''
UNION ALL
SELECT 'Customers Missing Phone' as Issue, COUNT(*) as Count
FROM Customer WHERE Phone IS NULL OR Phone = ''
UNION ALL
SELECT 'Customers Missing Address' as Issue, COUNT(*) as Count
FROM Customer WHERE Address1 IS NULL OR Address1 = '';

-- Customer financial summary
SELECT 
    'Total Credit Limit' as Metric,
    SUM(CAST(CreditLimit as DECIMAL(18,2))) as Amount
FROM Customer
WHERE CreditLimit IS NOT NULL
UNION ALL
SELECT 
    'Total Account Balance' as Metric,
    SUM(CAST(AccountBalance as DECIMAL(18,2))) as Amount
FROM Customer
WHERE AccountBalance IS NOT NULL
UNION ALL
SELECT 
    'Total Loyalty Points' as Metric,
    SUM(CAST(Points as DECIMAL(18,0))) as Amount
FROM Customer
WHERE Points IS NOT NULL;

-- ============================================
-- 2. PRODUCT VALIDATION
-- ============================================
PRINT ''
PRINT '=== PRODUCT VALIDATION ==='
PRINT ''

-- Total product count
SELECT 'Total Products in Aralco' as Metric, COUNT(*) as Count
FROM Product;

-- Active products
SELECT 'Active Products' as Metric, COUNT(*) as Count
FROM Product WHERE Status = 'A';

-- Products by category
SELECT TOP 10
    ISNULL(Category1, 'No Category') as Category,
    COUNT(*) as ProductCount
FROM Product
GROUP BY Category1
ORDER BY COUNT(*) DESC;

-- Product inventory value
SELECT 
    'Total Inventory Units' as Metric,
    SUM(CAST(OnHand as DECIMAL(18,0))) as Quantity
FROM Product
WHERE OnHand > 0
UNION ALL
SELECT 
    'Total Inventory Value' as Metric,
    SUM(CAST(OnHand as DECIMAL(18,2)) * CAST(Cost as DECIMAL(18,2))) as Value
FROM Product
WHERE OnHand > 0 AND Cost > 0;

-- Products missing critical data
SELECT 'Products Missing Description' as Issue, COUNT(*) as Count
FROM Product WHERE Description IS NULL OR Description = ''
UNION ALL
SELECT 'Products Missing Cost' as Issue, COUNT(*) as Count
FROM Product WHERE Cost IS NULL OR Cost = 0
UNION ALL
SELECT 'Products Missing Price' as Issue, COUNT(*) as Count
FROM Product WHERE SellPrice IS NULL OR SellPrice = 0;

-- ============================================
-- 3. TRANSACTION VALIDATION
-- ============================================
PRINT ''
PRINT '=== TRANSACTION VALIDATION ==='
PRINT ''

-- Transaction counts by period
SELECT 
    YEAR(TransDate) as Year,
    MONTH(TransDate) as Month,
    COUNT(*) as TransactionCount,
    SUM(CAST(Total as DECIMAL(18,2))) as TotalRevenue
FROM POSTransHead
WHERE Status = 'C'
  AND TransDate >= DATEADD(YEAR, -2, GETDATE())
GROUP BY YEAR(TransDate), MONTH(TransDate)
ORDER BY Year DESC, Month DESC;

-- Transaction summary
SELECT 
    'Total Transactions (Last 2 Years)' as Metric,
    COUNT(*) as Count
FROM POSTransHead
WHERE Status = 'C'
  AND TransDate >= DATEADD(YEAR, -2, GETDATE())
UNION ALL
SELECT 
    'Total Revenue (Last 2 Years)' as Metric,
    SUM(CAST(Total as DECIMAL(18,2))) as Amount
FROM POSTransHead
WHERE Status = 'C'
  AND TransDate >= DATEADD(YEAR, -2, GETDATE())
UNION ALL
SELECT 
    'Average Transaction Value' as Metric,
    AVG(CAST(Total as DECIMAL(18,2))) as Amount
FROM POSTransHead
WHERE Status = 'C'
  AND TransDate >= DATEADD(YEAR, -2, GETDATE());

-- Transactions by type
SELECT 
    TransType,
    COUNT(*) as Count,
    SUM(CAST(Total as DECIMAL(18,2))) as TotalAmount
FROM POSTransHead
WHERE Status = 'C'
  AND TransDate >= DATEADD(YEAR, -2, GETDATE())
GROUP BY TransType
ORDER BY COUNT(*) DESC;

-- Top customers by revenue
SELECT TOP 20
    c.CustomerID,
    c.CustomerNo,
    CASE 
        WHEN c.CompanyName IS NOT NULL AND c.CompanyName != '' THEN c.CompanyName
        ELSE ISNULL(c.FirstName, '') + ' ' + ISNULL(c.LastName, '')
    END as CustomerName,
    COUNT(DISTINCT h.POSTransHeadID) as OrderCount,
    SUM(CAST(h.Total as DECIMAL(18,2))) as TotalRevenue
FROM POSTransHead h
INNER JOIN Customer c ON h.CustomerID = c.POSCustomerID
WHERE h.Status = 'C'
  AND h.TransDate >= DATEADD(YEAR, -2, GETDATE())
GROUP BY c.CustomerID, c.CustomerNo, c.CompanyName, c.FirstName, c.LastName
ORDER BY SUM(CAST(h.Total as DECIMAL(18,2))) DESC;

-- ============================================
-- 4. DATA INTEGRITY CHECKS
-- ============================================
PRINT ''
PRINT '=== DATA INTEGRITY CHECKS ==='
PRINT ''

-- Orphaned transactions (no customer)
SELECT 'Transactions without Customer' as Issue, COUNT(*) as Count
FROM POSTransHead h
WHERE h.CustomerID NOT IN (SELECT POSCustomerID FROM Customer WHERE POSCustomerID IS NOT NULL)
  AND h.Status = 'C'
  AND h.TransDate >= DATEADD(YEAR, -2, GETDATE());

-- Orphaned line items (no product)
SELECT 'Line Items without Product' as Issue, COUNT(*) as Count
FROM POSTransItem i
INNER JOIN POSTransHead h ON i.POSTransHeadID = h.POSTransHeadID
WHERE i.ProductID NOT IN (SELECT ProductID FROM Product)
  AND h.Status = 'C'
  AND h.TransDate >= DATEADD(YEAR, -2, GETDATE());

-- Transaction totals reconciliation
SELECT 
    'Header Total' as Source,
    SUM(CAST(Total as DECIMAL(18,2))) as Amount
FROM POSTransHead
WHERE Status = 'C'
  AND TransDate >= DATEADD(YEAR, -2, GETDATE())
UNION ALL
SELECT 
    'Line Items Total' as Source,
    SUM(CAST(i.Quantity as DECIMAL(18,2)) * CAST(i.SellPrice as DECIMAL(18,2))) as Amount
FROM POSTransItem i
INNER JOIN POSTransHead h ON i.POSTransHeadID = h.POSTransHeadID
WHERE h.Status = 'C'
  AND h.TransDate >= DATEADD(YEAR, -2, GETDATE());

-- ============================================
-- 5. GENERATE VALIDATION SUMMARY
-- ============================================
PRINT ''
PRINT '=== VALIDATION SUMMARY ==='
PRINT ''
PRINT 'Run Date: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT 'Database: ' + DB_NAME()
PRINT ''
PRINT 'Key Metrics for Salesforce Comparison:'
PRINT '- Total Customers: Run count query in Salesforce'
PRINT '- Total Products: Run count query in Salesforce'  
PRINT '- Total Orders: Run count query in Salesforce'
PRINT '- Total Revenue: Run sum query in Salesforce'
PRINT ''
PRINT 'IMPORTANT: Compare these numbers with Salesforce after migration'
PRINT 'Any significant differences should be investigated'