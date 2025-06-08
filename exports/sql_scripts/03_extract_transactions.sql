-- ============================================
-- Aralco to Salesforce Migration
-- Transaction Data Extraction Script
-- ============================================
-- This script extracts transaction data from Aralco POS
-- and prepares it for Salesforce Order import
-- ============================================

USE AralcoPOS;
GO

-- Set date range for extraction (last 2 years of data)
DECLARE @StartDate DATETIME = DATEADD(YEAR, -2, GETDATE());
DECLARE @EndDate DATETIME = GETDATE();

-- Extract Transaction Headers (Orders)
SELECT 
    h.POSTransHeadID as Aralco_Transaction_ID__c,
    h.TransNo as OrderNumber,
    h.TransDate as EffectiveDate,
    c.CustomerID as Account_Aralco_ID__c, -- Will be mapped to Account
    h.StoreID as Store_ID__c,
    h.RegisterID as Register_ID__c,
    h.EmployeeID as Sales_Rep_ID__c,
    h.SubTotal as Subtotal__c,
    h.DiscountAmount as Discount_Amount__c,
    h.Tax1 as Tax_1__c,
    h.Tax2 as Tax_2__c,
    h.Total as TotalAmount,
    CASE h.TransType
        WHEN 'SALE' THEN 'Sale'
        WHEN 'RETURN' THEN 'Return'
        WHEN 'LAYAWAY' THEN 'Layaway'
        WHEN 'QUOTE' THEN 'Quote'
        ELSE 'Other'
    END as Type,
    CASE h.Status
        WHEN 'C' THEN 'Completed'
        WHEN 'V' THEN 'Voided'
        WHEN 'H' THEN 'On Hold'
        ELSE 'Draft'
    END as Status,
    h.PaymentType as Payment_Method__c,
    h.ReferenceNo as Reference_Number__c,
    h.Comments as Description,
    h.CreatedDate as Created_Date__c,
    h.ShipToName as ShipToName__c,
    h.ShipToAddress1 as ShipToStreet__c,
    h.ShipToCity as ShipToCity__c,
    h.ShipToProvince as ShipToState__c,
    h.ShipToPostalCode as ShipToPostalCode__c,
    h.ShipToCountry as ShipToCountry__c
INTO #OrderHeaders
FROM POSTransHead h
LEFT JOIN Customer c ON h.CustomerID = c.POSCustomerID
WHERE h.TransDate BETWEEN @StartDate AND @EndDate
  AND h.Status = 'C'; -- Only completed transactions

-- Extract Transaction Items (Order Products)
SELECT 
    i.POSTransItemID as Aralco_Line_Item_ID__c,
    i.POSTransHeadID as Order_Aralco_ID__c, -- Will be mapped to Order
    i.ProductID as Product_Aralco_ID__c, -- Will be mapped to Product2
    i.LineNo as Line_Number__c,
    i.Quantity as Quantity,
    i.SellPrice as UnitPrice,
    i.Cost as Cost__c,
    i.DiscountAmount as Discount__c,
    i.Tax1 as Tax_1__c,
    i.Tax2 as Tax_2__c,
    (i.Quantity * i.SellPrice - ISNULL(i.DiscountAmount, 0)) as TotalPrice,
    i.SerialNumber as Serial_Number__c,
    i.Description as Description,
    i.Notes as Line_Notes__c,
    CASE 
        WHEN i.IsReturn = 1 THEN 'true' 
        ELSE 'false' 
    END as Is_Return__c
FROM POSTransItem i
INNER JOIN #OrderHeaders h ON i.POSTransHeadID = h.Aralco_Transaction_ID__c;

-- Extract Payment Information
SELECT 
    p.POSTransPayID as Payment_ID__c,
    p.POSTransHeadID as Order_Aralco_ID__c,
    p.PaymentType as Payment_Type__c,
    p.Amount as Amount__c,
    p.TenderAmount as Tender_Amount__c,
    p.ChangeAmount as Change_Amount__c,
    p.AuthCode as Authorization_Code__c,
    p.ReferenceNo as Reference_Number__c,
    p.CardType as Card_Type__c,
    p.CardLastFour as Card_Last_Four__c,
    p.PaymentDate as Payment_Date__c
FROM POSTransPay p
INNER JOIN #OrderHeaders h ON p.POSTransHeadID = h.Aralco_Transaction_ID__c;

-- Transaction Summary by Customer
SELECT 
    c.CustomerID as Account_Aralco_ID__c,
    COUNT(DISTINCT h.POSTransHeadID) as Total_Orders__c,
    SUM(h.Total) as Total_Revenue__c,
    AVG(h.Total) as Average_Order_Value__c,
    MAX(h.TransDate) as Last_Order_Date__c,
    MIN(h.TransDate) as First_Order_Date__c
FROM POSTransHead h
INNER JOIN Customer c ON h.CustomerID = c.POSCustomerID
WHERE h.TransDate BETWEEN @StartDate AND @EndDate
  AND h.Status = 'C'
GROUP BY c.CustomerID;

-- Data Quality Report
PRINT '=== Transaction Data Quality Report ==='
PRINT ''

SELECT 
    'Total Transactions' as Metric,
    COUNT(*) as Count
FROM #OrderHeaders
UNION ALL
SELECT 
    'Transactions with Customer',
    COUNT(*) 
FROM #OrderHeaders 
WHERE Account_Aralco_ID__c IS NOT NULL
UNION ALL
SELECT 
    'Sales Transactions',
    COUNT(*) 
FROM #OrderHeaders 
WHERE Type = 'Sale'
UNION ALL
SELECT 
    'Return Transactions',
    COUNT(*) 
FROM #OrderHeaders 
WHERE Type = 'Return'
UNION ALL
SELECT 
    'Total Transaction Value',
    SUM(TotalAmount) 
FROM #OrderHeaders
UNION ALL
SELECT 
    'Average Transaction Value',
    AVG(TotalAmount) 
FROM #OrderHeaders;

-- Export final data
SELECT * FROM #OrderHeaders
ORDER BY EffectiveDate DESC, OrderNumber;

-- Cleanup
DROP TABLE #OrderHeaders;