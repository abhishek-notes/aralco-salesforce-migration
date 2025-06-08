-- ============================================
-- Aralco to Salesforce Migration
-- Customer Data Extraction Script
-- ============================================
-- This script extracts customer data from Aralco POS
-- and prepares it for Salesforce Account/Contact import
-- ============================================

USE AralcoPOS;
GO

-- Extract Business Accounts (Companies)
SELECT 
    'Business Account' as RecordType,
    c.CustomerID as Aralco_Customer_ID__c,
    c.CustomerNo as AccountNumber,
    c.CompanyName as Name,
    c.Phone as Phone,
    c.Fax as Fax,
    c.Email as Email,
    c.Address1 as BillingStreet,
    c.City as BillingCity,
    c.ProvinceState as BillingState,
    c.PostalCode as BillingPostalCode,
    ISNULL(c.Country, 'Canada') as BillingCountry,
    c.CreditLimit as Credit_Limit__c,
    c.AccountBalance as Account_Balance__c,
    c.Points as Loyalty_Points__c,
    c.LastPurchase as Last_Purchase_Date__c,
    c.CreatedDate as Aralco_Created_Date__c,
    CASE WHEN c.Deactivate = 1 THEN 'false' ELSE 'true' END as Active__c,
    c.AlertMessage as Alert_Message__c,
    c.Terms as Payment_Terms__c,
    c.ShipVia as Shipping_Method__c,
    c.CustomerGroupID as Customer_Group_ID__c,
    c.StoreID as Primary_Store_ID__c,
    c.DiscountRate as Discount_Rate__c,
    c.LastUpdated as LastModifiedDate,
    c.Remark as Description
INTO #BusinessAccounts
FROM Customer c
WHERE c.CompanyName IS NOT NULL 
  AND c.CompanyName != ''
  AND (c.FirstName IS NULL OR c.FirstName = '')
  AND (c.LastName IS NULL OR c.LastName = '');

-- Extract Person Accounts (Individuals)
SELECT 
    'Person Account' as RecordType,
    c.CustomerID as Aralco_Customer_ID__c,
    c.CustomerNo as AccountNumber,
    CASE 
        WHEN c.FirstName IS NOT NULL AND c.LastName IS NOT NULL 
        THEN LTRIM(RTRIM(c.FirstName + ' ' + c.LastName))
        WHEN c.FirstName IS NOT NULL 
        THEN c.FirstName
        WHEN c.LastName IS NOT NULL 
        THEN c.LastName
        ELSE 'Unknown Customer ' + CAST(c.CustomerID as VARCHAR)
    END as Name,
    c.FirstName as FirstName,
    c.LastName as LastName,
    c.Phone as PersonHomePhone,
    c.Phone2 as PersonOtherPhone,
    c.Cellular as PersonMobilePhone,
    c.Email as PersonEmail,
    c.Address1 as PersonMailingStreet,
    c.City as PersonMailingCity,
    c.ProvinceState as PersonMailingState,
    c.PostalCode as PersonMailingPostalCode,
    ISNULL(c.Country, 'Canada') as PersonMailingCountry,
    c.CreditLimit as Credit_Limit__c,
    c.AccountBalance as Account_Balance__c,
    c.Points as Loyalty_Points__c,
    c.LastPurchase as Last_Purchase_Date__c,
    c.CreatedDate as Aralco_Created_Date__c,
    CASE WHEN c.Deactivate = 1 THEN 'false' ELSE 'true' END as Active__c,
    c.AlertMessage as Alert_Message__c,
    c.Terms as Payment_Terms__c,
    c.ShipVia as Shipping_Method__c,
    c.CustomerGroupID as Customer_Group_ID__c,
    c.StoreID as Primary_Store_ID__c,
    c.DiscountRate as Discount_Rate__c,
    c.LastUpdated as LastModifiedDate,
    c.Remark as Description
INTO #PersonAccounts
FROM Customer c
WHERE (c.CompanyName IS NULL OR c.CompanyName = '')
   OR (c.FirstName IS NOT NULL AND c.FirstName != '')
   OR (c.LastName IS NOT NULL AND c.LastName != '');

-- Create final export combining both types
SELECT * FROM #BusinessAccounts
UNION ALL
SELECT * FROM #PersonAccounts
ORDER BY Aralco_Customer_ID__c;

-- Export Customer Groups for reference
SELECT DISTINCT
    CustomerGroupID,
    COUNT(*) as CustomerCount
FROM Customer
WHERE CustomerGroupID IS NOT NULL
GROUP BY CustomerGroupID
ORDER BY CustomerCount DESC;

-- Data Quality Report
PRINT '=== Customer Data Quality Report ==='
PRINT ''

SELECT 
    'Total Customers' as Metric,
    COUNT(*) as Count
FROM Customer
UNION ALL
SELECT 
    'Business Accounts',
    COUNT(*) 
FROM #BusinessAccounts
UNION ALL
SELECT 
    'Person Accounts',
    COUNT(*) 
FROM #PersonAccounts
UNION ALL
SELECT 
    'Customers with Email',
    COUNT(*) 
FROM Customer 
WHERE Email IS NOT NULL AND Email != ''
UNION ALL
SELECT 
    'Customers with Phone',
    COUNT(*) 
FROM Customer 
WHERE Phone IS NOT NULL AND Phone != ''
UNION ALL
SELECT 
    'Active Customers',
    COUNT(*) 
FROM Customer 
WHERE Deactivate != 1 OR Deactivate IS NULL
UNION ALL
SELECT 
    'Customers with Balance',
    COUNT(*) 
FROM Customer 
WHERE AccountBalance != 0 AND AccountBalance IS NOT NULL;

-- Cleanup
DROP TABLE #BusinessAccounts;
DROP TABLE #PersonAccounts;