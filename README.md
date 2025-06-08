# Aralco POS to Salesforce Migration Project

## Project Structure
```
aralco-salesforce-migration/
├── database/               # Database files
├── exports/               # Exported data and schemas
├── salesforce-metadata/   # Salesforce project files
├── setup_sql_server.sh    # Script to start SQL Server
├── copy_database_files.sh # Script to copy database files
├── attach_database.sql    # SQL script to attach database
└── MIGRATION_PROMPT.md    # Instructions for Claude Code
```

## Setup Instructions

### 1. Copy Database Files (if not already done)
```bash
chmod +x copy_database_files.sh
./copy_database_files.sh
```

### 2. Start New SQL Server Container
```bash
chmod +x setup_sql_server.sh
./setup_sql_server.sh
```

### 3. Attach Database in VS Code
1. Connect to SQL Server in VS Code (localhost,1433)
2. Open `attach_database.sql`
3. Run the script (Cmd+Shift+E)

### 4. Export Schema for Analysis
1. Open `exports/export_schema.sql` in VS Code
2. Run each section and save results

### 5. Copy Your Salesforce Project
Copy your Salesforce project files to the `salesforce-metadata` directory:
```bash
cp -r ~/path-to-your-salesforce-project/* ./salesforce-metadata/
```

### 6. Run Claude Code
```bash
cd ~/Work/aralco-salesforce-migration
claude-code
```

Then provide the MIGRATION_PROMPT.md content to Claude Code.

## Database Connection Details
- **Server**: localhost,1433
- **Username**: sa
- **Password**: YourStrong@Password123
- **Database**: AralcoPOS

## Important Files
- `MIGRATION_PROMPT.md` - Comprehensive instructions for Claude Code
- `exports/export_schema.sql` - SQL scripts to export database schema
- `attach_database.sql` - Script to attach database after container restart