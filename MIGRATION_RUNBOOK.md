# Aralco to Salesforce Migration Runbook

## Overview
This runbook provides step-by-step instructions for executing the Aralco POS to Salesforce migration.

## Pre-Migration Checklist

### Environment Setup
- [ ] Salesforce Production org access with System Administrator profile
- [ ] Salesforce Full Sandbox created and refreshed
- [ ] Data Loader installed (version 50.0 or higher)
- [ ] SQL Server Management Studio access to Aralco database
- [ ] Python 3.7+ installed for transformation scripts
- [ ] All stakeholders notified of migration schedule

### Salesforce Configuration
- [ ] Person Accounts enabled (if using individual customers)
- [ ] Multi-currency enabled (if required)
- [ ] API limits verified (minimum 100,000 calls available)
- [ ] Storage space verified (adequate for data volume)
- [ ] Integration user created with appropriate permissions

## Phase 1: Metadata Deployment (Day 1)

### Step 1.1: Deploy Custom Objects
```bash
cd /workspace/aralco-salesforce-migration/salesforce-metadata
sfdx force:source:deploy -p force-app/main/default/objects -u <sandbox-alias>
```

### Step 1.2: Deploy Custom Fields
1. Deploy Account fields:
   - Aralco_Customer_ID__c
   - Credit_Limit__c
   - Account_Balance__c
   - Loyalty_Points__c
   - Last_Purchase_Date__c

2. Deploy Product2 fields:
   - Aralco_Product_ID__c
   - Cost__c
   - Quantity_On_Hand__c
   - Department__c
   - Product_Category_2__c
   - Product_Category_3__c

3. Deploy Order fields:
   - Aralco_Transaction_ID__c
   - Store__c
   - Subtotal__c
   - Tax_1__c
   - Tax_2__c

### Step 1.3: Create Record Types
1. Account Record Types:
   - Business_Account
   - PersonAccount (if enabled)
   - Vendor

### Step 1.4: Page Layout Configuration
1. Update page layouts to include custom fields
2. Assign layouts to appropriate profiles
3. Configure field-level security

## Phase 2: Data Extraction (Day 2)

### Step 2.1: Connect to Aralco Database
```sql
-- Connect to SQL Server
Server: localhost,1433
Database: AralcoPOS
Username: sa
Password: YourStrong@Password123
```

### Step 2.2: Run Extraction Scripts
```bash
# Execute each script and save results as CSV
sqlcmd -S localhost,1433 -U sa -P YourStrong@Password123 -d AralcoPOS -i exports/sql_scripts/01_extract_customers.sql -o exports/raw/customers.csv -s","
sqlcmd -S localhost,1433 -U sa -P YourStrong@Password123 -d AralcoPOS -i exports/sql_scripts/02_extract_products.sql -o exports/raw/products.csv -s","
sqlcmd -S localhost,1433 -U sa -P YourStrong@Password123 -d AralcoPOS -i exports/sql_scripts/03_extract_transactions.sql -o exports/raw/transactions.csv -s","
```

### Step 2.3: Verify Extraction
- [ ] Customer count matches expected (13,111)
- [ ] Product count matches expected (37,028)
- [ ] Transaction count matches expected (37,677)
- [ ] No SQL errors in output

## Phase 3: Data Transformation (Day 3)

### Step 3.1: Run Transformation Scripts
```bash
cd /workspace/aralco-salesforce-migration
python3 transform_data.py
```

### Step 3.2: Verify Transformed Data
- [ ] Check exports/salesforce_ready/accounts/accounts_import.csv
- [ ] Check exports/salesforce_ready/products/products_import.csv
- [ ] Check exports/salesforce_ready/orders/orders_import.csv
- [ ] Review transformation_summary.json for errors

### Step 3.3: Data Quality Checks
1. Verify required fields are populated
2. Check for data truncation
3. Validate email formats
4. Confirm phone number standardization

## Phase 4: Data Loading - Test Run (Day 4)

### Step 4.1: Configure Data Loader
1. Launch Data Loader
2. Login to Sandbox
3. Configure settings:
   - Batch Size: 200
   - Insert Null Values: Yes
   - Time Zone: America/Toronto

### Step 4.2: Test Load - Small Batch
1. Load first 100 accounts
2. Load first 100 products
3. Verify in Salesforce UI
4. Check for errors

### Step 4.3: Validation
```soql
-- Verify accounts loaded
SELECT COUNT() FROM Account WHERE Aralco_Customer_ID__c != null

-- Verify products loaded
SELECT COUNT() FROM Product2 WHERE Aralco_Product_ID__c != null

-- Check for duplicates
SELECT Aralco_Customer_ID__c, COUNT(Id) 
FROM Account 
WHERE Aralco_Customer_ID__c != null 
GROUP BY Aralco_Customer_ID__c 
HAVING COUNT(Id) > 1
```

## Phase 5: Full Data Load (Day 5-6)

### Step 5.1: Load Master Data
1. **Accounts** (13,111 records)
   ```bash
   dataloader.bat process ../dataloader/process-conf.xml accountImport
   ```

2. **Products** (37,028 records)
   ```bash
   dataloader.bat process ../dataloader/process-conf.xml productImport
   ```

3. **Price Book Entries**
   ```bash
   dataloader.bat process ../dataloader/process-conf.xml pricebookImport
   ```

### Step 5.2: Load Transactional Data
1. **Orders** (37,677 records)
   ```bash
   dataloader.bat process ../dataloader/process-conf.xml orderImport
   ```

2. **Order Items** (49,788 records)
   ```bash
   dataloader.bat process ../dataloader/process-conf.xml orderItemImport
   ```

### Step 5.3: Monitor Progress
- Check Data Loader logs
- Monitor API usage
- Track error files
- Update stakeholders

## Phase 6: Validation (Day 7)

### Step 6.1: Record Count Validation
```soql
-- Accounts
SELECT COUNT() FROM Account WHERE Aralco_Customer_ID__c != null
-- Expected: 13,111

-- Products
SELECT COUNT() FROM Product2 WHERE Aralco_Product_ID__c != null
-- Expected: 37,028

-- Orders
SELECT COUNT() FROM Order WHERE Aralco_Transaction_ID__c != null
-- Expected: 37,677
```

### Step 6.2: Financial Validation
```soql
-- Total Order Amount
SELECT SUM(TotalAmount) FROM Order WHERE Aralco_Transaction_ID__c != null

-- Compare with Aralco total
```

### Step 6.3: Relationship Validation
```soql
-- Orders with Accounts
SELECT COUNT() FROM Order 
WHERE AccountId != null 
AND Aralco_Transaction_ID__c != null

-- Order Items with Products
SELECT COUNT() FROM OrderItem 
WHERE Product2Id != null 
AND Aralco_Line_Item_ID__c != null
```

### Step 6.4: Sample Record Verification
1. Select 10 random customers
2. Compare all fields with source
3. Verify order history
4. Check calculations

## Phase 7: User Acceptance Testing (Day 8-9)

### Step 7.1: UAT Scenarios
1. Search for customer by name
2. View customer order history
3. Check product inventory levels
4. Run standard reports
5. Create new order

### Step 7.2: Performance Testing
1. Measure page load times
2. Test bulk operations
3. Verify search performance
4. Check report generation

## Phase 8: Production Migration (Day 10)

### Step 8.1: Final Backup
1. Backup Salesforce metadata
2. Export existing data (if any)
3. Document current state

### Step 8.2: Production Deployment
1. Repeat all phases in Production
2. Use same validation queries
3. Monitor more closely
4. Have rollback plan ready

### Step 8.3: Go-Live Checklist
- [ ] All data loaded successfully
- [ ] Validation complete
- [ ] Users trained
- [ ] Support team ready
- [ ] Rollback plan tested
- [ ] Stakeholders notified

## Post-Migration Tasks

### Immediate (Day 11)
1. Monitor system performance
2. Address user issues
3. Verify integration points
4. Check automated processes

### Week 1
1. Daily data quality checks
2. User feedback collection
3. Performance optimization
4. Issue resolution

### Month 1
1. Full data audit
2. Process refinement
3. Training reinforcement
4. Success metrics review

## Troubleshooting

### Common Issues

#### Duplicate Records
```soql
-- Find duplicates
SELECT Aralco_Customer_ID__c, COUNT(Id) 
FROM Account 
GROUP BY Aralco_Customer_ID__c 
HAVING COUNT(Id) > 1

-- Solution: Delete duplicates keeping newest
```

#### Missing Relationships
```soql
-- Find orders without accounts
SELECT Id, Aralco_Transaction_ID__c 
FROM Order 
WHERE AccountId = null

-- Solution: Re-run with updated mapping
```

#### Data Type Errors
- Check transformation logs
- Verify field types match
- Update transformation script

### Emergency Contacts
- Salesforce Support: 1-800-NO-SOFTWARE
- Database Admin: [Contact]
- Project Manager: [Contact]
- Technical Lead: [Contact]

## Rollback Procedure

### If Critical Issues Occur:
1. Stop all data loading
2. Document issues found
3. Execute rollback scripts:
   ```apex
   // Delete all migrated records
   DELETE [SELECT Id FROM Account WHERE Aralco_Customer_ID__c != null];
   DELETE [SELECT Id FROM Product2 WHERE Aralco_Product_ID__c != null];
   DELETE [SELECT Id FROM Order WHERE Aralco_Transaction_ID__c != null];
   ```
4. Restore metadata backups
5. Notify stakeholders
6. Plan remediation

## Sign-Off

### Migration Completion Checklist
- [ ] All data migrated successfully
- [ ] Validation complete
- [ ] UAT passed
- [ ] Performance acceptable
- [ ] Users trained
- [ ] Documentation complete

### Approvals
- Business Owner: _________________ Date: _______
- IT Manager: _________________ Date: _______
- Project Manager: _________________ Date: _______
- Technical Lead: _________________ Date: _______