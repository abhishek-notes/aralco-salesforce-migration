# Aralco POS to Salesforce Migration Analysis Request

## Project Context
I have an Aralco POS system database that I need to migrate to Salesforce Sales Cloud. I need you to analyze both systems and create a comprehensive migration strategy.

## Directory Structure
```
~/Work/aralco-salesforce-migration/
├── database/
│   ├── AralcoPOS.mdf
│   ├── AralcoPOS_log.ldf
│   └── AralcoBOS20250426@151908-001-copy.bak
├── exports/
│   └── [Schema exports will go here]
└── salesforce-metadata/
    └── [Your Salesforce manifest and code]
```

## Database Access
- SQL Server running in Docker on localhost:1433
- Username: sa
- Password: YourStrong@Password123
- Database name: AralcoPOS

## Task Requirements

### 1. Database Analysis
Please analyze the Aralco POS database and:
- Identify all customer-related tables
- Identify all product/inventory tables
- Identify all sales/transaction tables
- Map relationships between tables
- Identify data quality issues (duplicates, missing data, etc.)

### 2. Salesforce Structure Analysis
Review my Salesforce org structure:
- Check existing custom objects in the manifest
- Identify standard objects to be used
- Review existing fields and relationships
- Check for any existing integrations

### 3. Migration Strategy Development
Create a comprehensive migration plan that includes:

#### A. Data Mapping Document
- Create detailed field mappings (Aralco → Salesforce)
- Identify data transformations needed
- Handle data type conversions
- Plan for maintaining referential integrity

#### B. Migration Scripts
Generate SQL scripts to:
- Export data in Salesforce-ready format
- Clean and transform data
- Create external ID mappings
- Handle parent-child relationships

#### C. Salesforce Metadata
Generate package.xml and metadata for:
- Custom objects (if needed)
- Custom fields
- Record types
- Page layouts
- Validation rules
- Process automation (flows/triggers)

#### D. Data Loader Configuration
Create:
- Mapping files for Data Loader
- Process-conf.xml for automation
- Batch scripts for sequential loading

#### E. Migration Sequence
Define the order of operations:
1. Prerequisites and setup
2. Data extraction queries
3. Transformation procedures
4. Loading sequence
5. Validation queries

### 4. Code Generation
Please generate:
- SQL extraction scripts for each object
- Python/Node.js scripts for data transformation
- Apex classes for post-migration processing
- Test data validation scripts

### 5. Documentation
Create:
- Technical migration guide
- Data dictionary
- Rollback procedures
- Post-migration validation checklist

## Specific Questions to Answer
1. What's the total data volume for migration?
2. Which tables contain the most critical business data?
3. What data quality issues exist that need cleaning?
4. Which Salesforce features should we leverage (Person Accounts, Price Books, etc.)?
5. What's the recommended migration approach (Big Bang vs Phased)?

## Deliverables Needed
1. Complete field mapping spreadsheet (CSV format)
2. SQL scripts directory with all extraction queries
3. Salesforce metadata package ready for deployment
4. Data transformation scripts
5. Step-by-step migration runbook
6. Post-migration validation suite

Please start by connecting to the database and analyzing the schema, then proceed with the migration strategy.