#!/usr/bin/env python3
"""
Aralco to Salesforce Data Transformation Script
Transforms exported Aralco data into Salesforce-ready format
"""

import csv
import json
import re
from datetime import datetime
import os

# Create output directories
os.makedirs('exports/salesforce_ready', exist_ok=True)
os.makedirs('exports/salesforce_ready/accounts', exist_ok=True)
os.makedirs('exports/salesforce_ready/products', exist_ok=True)
os.makedirs('exports/salesforce_ready/orders', exist_ok=True)

class DataTransformer:
    """Main data transformation class"""
    
    def __init__(self):
        self.errors = []
        self.stats = {
            'accounts_processed': 0,
            'products_processed': 0,
            'orders_processed': 0,
            'errors': 0
        }
    
    def clean_phone(self, phone):
        """Standardize phone number format"""
        if not phone:
            return ''
        # Remove all non-numeric characters
        clean = re.sub(r'[^0-9]', '', str(phone))
        # Format as (XXX) XXX-XXXX if 10 digits
        if len(clean) == 10:
            return f"({clean[:3]}) {clean[3:6]}-{clean[6:]}"
        return phone
    
    def clean_email(self, email):
        """Validate and clean email address"""
        if not email:
            return ''
        email = str(email).strip().lower()
        # Basic email validation
        if re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', email):
            return email
        return ''
    
    def clean_currency(self, value):
        """Clean currency values"""
        if not value:
            return '0.00'
        try:
            # Remove currency symbols and commas
            clean = re.sub(r'[$,]', '', str(value))
            return f"{float(clean):.2f}"
        except:
            return '0.00'
    
    def transform_date(self, date_str):
        """Transform date to Salesforce format (YYYY-MM-DD)"""
        if not date_str:
            return ''
        try:
            # Try various date formats
            for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y']:
                try:
                    dt = datetime.strptime(str(date_str).split('.')[0], fmt)
                    return dt.strftime('%Y-%m-%d')
                except:
                    continue
            return str(date_str)[:10]  # Fallback: take first 10 chars
        except:
            return ''
    
    def transform_datetime(self, datetime_str):
        """Transform datetime to Salesforce format (YYYY-MM-DD'T'HH:MM:SS.000Z)"""
        if not datetime_str:
            return ''
        try:
            # Parse datetime
            dt_str = str(datetime_str).split('.')[0]
            dt = datetime.strptime(dt_str, '%Y-%m-%d %H:%M:%S')
            return dt.strftime('%Y-%m-%dT%H:%M:%S.000Z')
        except:
            # Try date only
            date = self.transform_date(datetime_str)
            if date:
                return f"{date}T00:00:00.000Z"
            return ''
    
    def transform_boolean(self, value):
        """Transform to Salesforce boolean"""
        if not value:
            return 'false'
        val = str(value).upper()
        if val in ['1', 'TRUE', 'YES', 'Y', 'T']:
            return 'true'
        return 'false'
    
    def transform_accounts(self, input_file='exports/analysis/customer_sample.csv'):
        """Transform customer data to Salesforce Account format"""
        print("🔄 Transforming Account data...")
        
        output_file = 'exports/salesforce_ready/accounts/accounts_import.csv'
        
        # Define field mappings
        fieldnames = [
            'RecordType.DeveloperName',
            'Aralco_Customer_ID__c',
            'AccountNumber', 
            'Name',
            'Phone',
            'Fax',
            'Website',
            'BillingStreet',
            'BillingCity',
            'BillingState',
            'BillingPostalCode',
            'BillingCountry',
            'ShippingStreet',
            'ShippingCity', 
            'ShippingState',
            'ShippingPostalCode',
            'ShippingCountry',
            'Description',
            'Industry',
            'AnnualRevenue',
            'NumberOfEmployees',
            'Credit_Limit__c',
            'Account_Balance__c',
            'Loyalty_Points__c',
            'Last_Purchase_Date__c',
            'Active__c',
            'PersonEmail',
            'PersonMobilePhone',
            'PersonHomePhone',
            'FirstName',
            'LastName'
        ]
        
        try:
            with open(input_file, 'r', encoding='utf-8') as infile, \
                 open(output_file, 'w', newline='', encoding='utf-8') as outfile:
                
                reader = csv.DictReader(infile)
                writer = csv.DictWriter(outfile, fieldnames=fieldnames)
                writer.writeheader()
                
                for row in reader:
                    try:
                        # Determine if business or person account
                        is_person = not row.get('CompanyName') or row.get('CompanyName').strip() == ''
                        
                        # Build account name
                        if is_person:
                            fname = (row.get('FirstName') or '').strip()
                            lname = (row.get('LastName') or '').strip()
                            name = f"{fname} {lname}".strip()
                            if not name:
                                name = f"Customer {row.get('CustomerID', 'Unknown')}"
                        else:
                            name = row.get('CompanyName', '').strip()
                        
                        # Transform record
                        transformed = {
                            'RecordType.DeveloperName': 'PersonAccount' if is_person else 'Business_Account',
                            'Aralco_Customer_ID__c': row.get('CustomerID', ''),
                            'AccountNumber': row.get('CustomerNo', ''),
                            'Name': name[:255],  # Salesforce limit
                            'Phone': self.clean_phone(row.get('Phone', '')),
                            'Fax': self.clean_phone(row.get('Fax', '')),
                            'Website': '',
                            'BillingStreet': row.get('Address1', ''),
                            'BillingCity': row.get('City', ''),
                            'BillingState': row.get('ProvinceState', ''),
                            'BillingPostalCode': row.get('PostalCode', ''),
                            'BillingCountry': row.get('Country', 'Canada'),
                            'ShippingStreet': row.get('Address1', ''),
                            'ShippingCity': row.get('City', ''),
                            'ShippingState': row.get('ProvinceState', ''),
                            'ShippingPostalCode': row.get('PostalCode', ''),
                            'ShippingCountry': row.get('Country', 'Canada'),
                            'Description': row.get('Remark', ''),
                            'Industry': '',
                            'AnnualRevenue': '',
                            'NumberOfEmployees': '',
                            'Credit_Limit__c': self.clean_currency(row.get('CreditLimit', 0)),
                            'Account_Balance__c': self.clean_currency(row.get('AccountBalance', 0)),
                            'Loyalty_Points__c': row.get('Points', '0'),
                            'Last_Purchase_Date__c': self.transform_date(row.get('LastPurchase', '')),
                            'Active__c': 'true',  # Assuming all exported are active
                            'PersonEmail': self.clean_email(row.get('Email', '')) if is_person else '',
                            'PersonMobilePhone': self.clean_phone(row.get('Cellular', '')) if is_person else '',
                            'PersonHomePhone': self.clean_phone(row.get('Phone', '')) if is_person else '',
                            'FirstName': row.get('FirstName', '') if is_person else '',
                            'LastName': row.get('LastName', '') if is_person else ''
                        }
                        
                        writer.writerow(transformed)
                        self.stats['accounts_processed'] += 1
                        
                    except Exception as e:
                        self.errors.append(f"Account {row.get('CustomerID', 'Unknown')}: {str(e)}")
                        self.stats['errors'] += 1
            
            print(f"✅ Transformed {self.stats['accounts_processed']} accounts")
            
        except Exception as e:
            print(f"❌ Error transforming accounts: {e}")
    
    def transform_products(self, input_file='exports/analysis/product_sample.csv'):
        """Transform product data to Salesforce Product2 format"""
        print("🔄 Transforming Product data...")
        
        output_file = 'exports/salesforce_ready/products/products_import.csv'
        pricebook_file = 'exports/salesforce_ready/products/pricebook_entries.csv'
        
        # Product fields
        product_fields = [
            'Aralco_Product_ID__c',
            'ProductCode',
            'Name',
            'Description',
            'Family',
            'IsActive',
            'Product_Category_2__c',
            'Product_Category_3__c',
            'Department__c',
            'Cost__c',
            'Quantity_On_Hand__c',
            'Brand__c',
            'UPC__c',
            'Weight__c',
            'Taxable__c',
            'Discountable__c'
        ]
        
        # PricebookEntry fields
        pricebook_fields = [
            'Product2.Aralco_Product_ID__c',
            'Pricebook2.Name',
            'UnitPrice',
            'IsActive',
            'UseStandardPrice'
        ]
        
        try:
            with open(input_file, 'r', encoding='utf-8') as infile, \
                 open(output_file, 'w', newline='', encoding='utf-8') as prod_out, \
                 open(pricebook_file, 'w', newline='', encoding='utf-8') as price_out:
                
                reader = csv.DictReader(infile)
                prod_writer = csv.DictWriter(prod_out, fieldnames=product_fields)
                price_writer = csv.DictWriter(price_out, fieldnames=pricebook_fields)
                
                prod_writer.writeheader()
                price_writer.writeheader()
                
                for row in reader:
                    try:
                        # Transform product
                        product = {
                            'Aralco_Product_ID__c': row.get('ProductID', ''),
                            'ProductCode': row.get('Code', ''),
                            'Name': (row.get('Description', '') or row.get('Code', 'Unknown'))[:255],
                            'Description': row.get('ShortDescription', ''),
                            'Family': row.get('Category1', ''),
                            'IsActive': 'true' if row.get('Status') == 'A' else 'false',
                            'Product_Category_2__c': row.get('Category2', ''),
                            'Product_Category_3__c': row.get('Category3', ''),
                            'Department__c': row.get('Department', ''),
                            'Cost__c': self.clean_currency(row.get('Cost', 0)),
                            'Quantity_On_Hand__c': row.get('OnHand', '0'),
                            'Brand__c': row.get('Brand', ''),
                            'UPC__c': row.get('UPC', ''),
                            'Weight__c': row.get('Weight', ''),
                            'Taxable__c': 'true',  # Default
                            'Discountable__c': 'true'  # Default
                        }
                        prod_writer.writerow(product)
                        
                        # Create pricebook entry
                        if row.get('SellPrice'):
                            price_entry = {
                                'Product2.Aralco_Product_ID__c': row.get('ProductID', ''),
                                'Pricebook2.Name': 'Standard Price Book',
                                'UnitPrice': self.clean_currency(row.get('SellPrice', 0)),
                                'IsActive': 'true' if row.get('Status') == 'A' else 'false',
                                'UseStandardPrice': 'false'
                            }
                            price_writer.writerow(price_entry)
                        
                        self.stats['products_processed'] += 1
                        
                    except Exception as e:
                        self.errors.append(f"Product {row.get('ProductID', 'Unknown')}: {str(e)}")
                        self.stats['errors'] += 1
            
            print(f"✅ Transformed {self.stats['products_processed']} products")
            
        except Exception as e:
            print(f"❌ Error transforming products: {e}")
    
    def generate_summary(self):
        """Generate transformation summary"""
        summary = {
            'transformation_date': datetime.now().isoformat(),
            'statistics': self.stats,
            'errors': self.errors[:100]  # First 100 errors
        }
        
        with open('exports/salesforce_ready/transformation_summary.json', 'w') as f:
            json.dump(summary, f, indent=2)
        
        print("\n📊 Transformation Summary:")
        print(f"  - Accounts processed: {self.stats['accounts_processed']}")
        print(f"  - Products processed: {self.stats['products_processed']}")
        print(f"  - Orders processed: {self.stats['orders_processed']}")
        print(f"  - Errors encountered: {self.stats['errors']}")

def main():
    """Main transformation process"""
    print("🚀 Starting Aralco to Salesforce Data Transformation...")
    
    transformer = DataTransformer()
    
    # Transform each entity type
    transformer.transform_accounts()
    transformer.transform_products()
    # transformer.transform_orders()  # Add when transaction data is available
    
    # Generate summary
    transformer.generate_summary()
    
    print("\n✅ Transformation complete! Check exports/salesforce_ready/ for results.")

if __name__ == "__main__":
    main()