# Aralco to Salesforce Data Dictionary

## Overview
This document provides detailed field-level documentation for the Aralco POS to Salesforce migration, including data types, transformations, and business rules.

## 1. Account Object (from Customer Table)

### Standard Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| Name | Text(255) | CompanyName or FirstName + LastName | Account name | Required; Use company name for business accounts, full name for person accounts |
| AccountNumber | Text(40) | CustomerNo | Unique customer number | Unique; Format: P03A-XXXXXXXX |
| Type | Picklist | Derived | Customer vs Vendor | Set based on source table |
| Phone | Phone | Phone | Primary phone | Standardize to (XXX) XXX-XXXX |
| Fax | Phone | Fax | Fax number | Standardize to (XXX) XXX-XXXX |
| Website | URL | - | Company website | Not available in Aralco |
| Industry | Picklist | - | Industry classification | Default to 'Other' |
| RecordTypeId | Lookup | Derived | Record type | Business_Account, PersonAccount, or Vendor |

### Billing Address Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| BillingStreet | TextArea(255) | Address1 | Street address | May contain multiple lines |
| BillingCity | Text(40) | City | City name | Proper case |
| BillingState | Text(80) | ProvinceState | State/Province | Use standard codes |
| BillingPostalCode | Text(20) | PostalCode | Postal/ZIP code | Canadian format: A1A 1A1 |
| BillingCountry | Text(80) | Country | Country name | Default: 'Canada' if null |

### Person Account Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| FirstName | Text(40) | FirstName | First name | Person accounts only |
| LastName | Text(80) | LastName | Last name | Person accounts only |
| PersonEmail | Email | Email | Personal email | Validate format |
| PersonHomePhone | Phone | Phone | Home phone | Standardize format |
| PersonMobilePhone | Phone | Cellular | Mobile phone | Standardize format |
| PersonOtherPhone | Phone | Phone2 | Other phone | Standardize format |

### Custom Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| Aralco_Customer_ID__c | Text(20) | CustomerID | External ID | Unique, External ID |
| Credit_Limit__c | Currency(16,2) | CreditLimit | Credit limit | Default: 0.00 |
| Account_Balance__c | Currency(16,2) | AccountBalance | Current balance | Can be negative |
| Loyalty_Points__c | Number(18,0) | Points | Loyalty points | Default: 0 |
| Last_Purchase_Date__c | DateTime | LastPurchase | Last purchase | May be null |
| Customer_Group__c | Lookup | CustomerGroupID | Customer group | Map to custom object |
| Alert_Message__c | LongTextArea(500) | AlertMessage | POS alerts | Display warnings |
| Payment_Terms__c | Text(50) | Terms | Payment terms | e.g., 'Net 30' |
| Discount_Rate__c | Percent(5,2) | DiscountRate | Default discount | 0-100% |
| Active__c | Checkbox | Deactivate | Is active | Inverse of Deactivate |
| Primary_Store_ID__c | Text(10) | StoreID | Primary store | Reference to Store__c |

## 2. Product2 Object (from Product Table)

### Standard Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| Name | Text(255) | Description | Product name | Required; Truncate if >255 |
| ProductCode | Text(255) | Code | SKU/Product code | Unique per product |
| Description | LongTextArea(4000) | ShortDescription | Product description | Rich text allowed |
| Family | Picklist | Category1 | Product family | Create picklist values |
| IsActive | Checkbox | Status | Active status | 'A' = true, else false |
| QuantityUnitOfMeasure | Picklist | Unit | Unit of measure | Default: 'Each' |
| StockKeepingUnit | Text(180) | Code | SKU | Same as ProductCode |

### Custom Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| Aralco_Product_ID__c | Text(20) | ProductID | External ID | Unique, External ID |
| Cost__c | Currency(16,2) | Cost | Product cost | For margin calculation |
| Quantity_On_Hand__c | Number(18,0) | OnHand | Current inventory | Updated regularly |
| Department__c | Text(100) | Department | Department | For categorization |
| Product_Category_2__c | Text(255) | Category2 | Sub-category | Secondary classification |
| Product_Category_3__c | Text(255) | Category3 | Sub-sub-category | Tertiary classification |
| Supplier__c | Lookup | Supplier | Supplier code | Map to Account (Vendor) |
| Brand__c | Text(100) | Brand | Brand name | For filtering |
| Model__c | Text(100) | Model | Model number | Product variant |
| Color__c | Text(50) | Color | Color | Product attribute |
| Size__c | Text(50) | Size | Size | Product attribute |
| UPC__c | Text(20) | UPC | Barcode | Universal Product Code |
| Weight__c | Number(10,2) | Weight | Product weight | In specified unit |
| Volume__c | Number(10,2) | Volume | Product volume | In specified unit |
| Minimum_Quantity__c | Number(10,0) | MinQty | Min stock level | Reorder trigger |
| Maximum_Quantity__c | Number(10,0) | MaxQty | Max stock level | Inventory cap |
| Reorder_Point__c | Number(10,0) | ReorderPoint | Reorder trigger | When to reorder |
| Reorder_Quantity__c | Number(10,0) | ReorderQty | Order quantity | How much to order |
| Lead_Time_Days__c | Number(5,0) | LeadTime | Lead time | Days to receive |
| Taxable__c | Checkbox | Taxable1 | Is taxable | For tax calculation |
| Discountable__c | Checkbox | Discountable | Allow discounts | Discount eligibility |
| Available_Online__c | Checkbox | WebItem | Web enabled | Show on website |
| Internal_Notes__c | LongTextArea(2000) | Notes | Internal notes | Staff only |

## 3. Order Object (from POSTransHead Table)

### Standard Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| OrderNumber | Text(30) | TransNo | Transaction number | Unique identifier |
| EffectiveDate | Date | TransDate | Transaction date | Required |
| AccountId | Lookup | CustomerID | Customer | Via Aralco_Customer_ID__c |
| Status | Picklist | Status | Order status | C=Completed, V=Voided |
| Type | Picklist | TransType | Transaction type | SALE, RETURN, etc. |
| TotalAmount | Currency(16,2) | Total | Order total | Sum of all charges |
| Description | LongTextArea(32000) | Comments | Order notes | Optional |

### Custom Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| Aralco_Transaction_ID__c | Text(20) | POSTransHeadID | External ID | Unique, External ID |
| Store__c | Lookup | StoreID | Store location | Map to Store__c object |
| Register_ID__c | Text(10) | RegisterID | POS register | Terminal identifier |
| Sales_Rep__c | Lookup | EmployeeID | Sales person | Map to User |
| Subtotal__c | Currency(16,2) | SubTotal | Before tax/discount | Line items total |
| Discount_Amount__c | Currency(16,2) | DiscountAmount | Total discount | Applied discounts |
| Tax_1__c | Currency(16,2) | Tax1 | Primary tax | GST/PST |
| Tax_2__c | Currency(16,2) | Tax2 | Secondary tax | HST/other |
| Payment_Method__c | Text(50) | PaymentType | Payment type | Cash, Credit, etc. |
| Reference_Number__c | Text(50) | ReferenceNo | External ref | PO number, etc. |

### Shipping Address Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| ShipToName__c | Text(255) | ShipToName | Recipient name | Override account |
| ShipToStreet__c | Text(255) | ShipToAddress1 | Street address | Shipping location |
| ShipToCity__c | Text(40) | ShipToCity | City | Shipping city |
| ShipToState__c | Text(80) | ShipToProvince | State/Province | Shipping state |
| ShipToPostalCode__c | Text(20) | ShipToPostalCode | Postal code | Shipping ZIP |
| ShipToCountry__c | Text(80) | ShipToCountry | Country | Default: Canada |

## 4. OrderItem Object (from POSTransItem Table)

### Standard Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| OrderId | Lookup | POSTransHeadID | Parent order | Via external ID |
| Product2Id | Lookup | ProductID | Product | Via external ID |
| Quantity | Number(18,2) | Quantity | Quantity sold | Can be negative |
| UnitPrice | Currency(16,2) | SellPrice | Unit price | At time of sale |
| TotalPrice | Currency(16,2) | Calculated | Line total | Quantity × Price |
| Description | Text(255) | Description | Line description | Override product |

### Custom Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| Aralco_Line_Item_ID__c | Text(20) | POSTransItemID | External ID | Unique, External ID |
| Line_Number__c | Number(5,0) | LineNo | Line sequence | Display order |
| Cost__c | Currency(16,2) | Cost | Unit cost | For margin calc |
| Discount__c | Currency(16,2) | DiscountAmount | Line discount | Applied discount |
| Tax_1__c | Currency(16,2) | Tax1 | Line tax 1 | Item-level tax |
| Tax_2__c | Currency(16,2) | Tax2 | Line tax 2 | Secondary tax |
| Serial_Number__c | Text(50) | SerialNumber | Serial number | For tracking |
| Line_Notes__c | LongTextArea(500) | Notes | Line notes | Additional info |
| Is_Return__c | Checkbox | IsReturn | Return flag | True if return |

## 5. Store__c Object (from Store Table)

### Custom Object Fields
| Salesforce Field | Type | Source Field | Description | Business Rules |
|-----------------|------|--------------|-------------|----------------|
| Name | Text(80) | Name | Store name | Required, unique |
| Aralco_Store_ID__c | Text(10) | StoreID | External ID | Unique, External ID |
| Store_Code__c | Text(20) | Code | Store code | Short identifier |
| Address__c | TextArea(255) | Address | Street address | Full address |
| City__c | Text(40) | City | City | Store city |
| State__c | Text(80) | Province | State/Province | Standard codes |
| Postal_Code__c | Text(20) | PostalCode | ZIP/Postal | Format validated |
| Country__c | Text(80) | Country | Country | Default: Canada |
| Phone__c | Phone | Phone | Store phone | Main contact |
| Manager__c | Lookup | ManagerID | Store manager | User lookup |
| Is_Active__c | Checkbox | Active | Active status | Operating store |
| Opening_Date__c | Date | OpenDate | Open date | Historical |

## 6. Data Transformation Rules

### Phone Number Formatting
- Remove all non-numeric characters
- Format as (XXX) XXX-XXXX for 10-digit numbers
- Leave unchanged if not 10 digits
- Null/empty remains null

### Email Validation
- Convert to lowercase
- Validate against regex pattern
- Set to null if invalid format
- Remove leading/trailing spaces

### Currency Handling
- Remove currency symbols ($, ¥, €)
- Remove thousand separators (,)
- Round to 2 decimal places
- Null/empty becomes 0.00

### Date/DateTime Formatting
- Dates: YYYY-MM-DD
- DateTimes: YYYY-MM-DD'T'HH:MM:SS.000Z
- Null remains null
- Invalid dates logged as errors

### Boolean Conversion
- 1, TRUE, YES, Y, T → true
- 0, FALSE, NO, N, F → false
- Null/empty → false

### Text Truncation
- Name fields: 255 characters
- Description: 4000 characters
- Notes: 32000 characters
- Preserve complete data in staging

## 7. Validation Rules

### Account Validation
1. Name is required
2. Either CompanyName or FirstName+LastName must exist
3. Email format if provided
4. Phone format if provided
5. Credit limit >= 0
6. Loyalty points >= 0

### Product Validation
1. Name is required (use Code if Description empty)
2. ProductCode is unique
3. Cost >= 0
4. Price >= 0
5. Quantity >= 0
6. IsActive must be true/false

### Order Validation
1. OrderNumber is required
2. EffectiveDate is required
3. AccountId must exist
4. TotalAmount = Subtotal + Tax - Discount
5. Status must be valid picklist value

### OrderItem Validation
1. OrderId is required
2. Product2Id is required
3. Quantity != 0
4. UnitPrice >= 0
5. TotalPrice = Quantity × UnitPrice - Discount

## 8. Error Handling

### Missing Required Fields
- Generate default values where possible
- Log error with record identifier
- Continue processing other records
- Report summary at end

### Invalid References
- Log orphaned records
- Create placeholder records if needed
- Mark for manual review
- Maintain referential integrity

### Data Type Mismatches
- Attempt type conversion
- Use default value if conversion fails
- Log transformation error
- Include in error report

### Duplicate Records
- Use upsert with external ID
- Update existing record
- Log duplicate occurrence
- Maintain newest data