"""
Migration script to add currency column to incomes table
Run this once to update existing database schema
"""
from app import create_app, db
from sqlalchemy import text

def migrate_add_currency():
    app = create_app()
    with app.app_context():
        try:
            # Check if currency column exists
            result = db.session.execute(text("PRAGMA table_info(incomes)"))
            columns = [row[1] for row in result]
            
            if 'currency' not in columns:
                print("Adding 'currency' column to incomes table...")
                db.session.execute(text(
                    "ALTER TABLE incomes ADD COLUMN currency VARCHAR(3) DEFAULT 'INR' NOT NULL"
                ))
                db.session.commit()
                print("✓ Successfully added 'currency' column")
            else:
                print("✓ 'currency' column already exists")
            
            # Check if updated_at column exists
            if 'updated_at' not in columns:
                print("Adding 'updated_at' column to incomes table...")
                # SQLite doesn't support CURRENT_TIMESTAMP as default in ALTER TABLE
                # Add column as nullable first
                db.session.execute(text(
                    "ALTER TABLE incomes ADD COLUMN updated_at DATETIME"
                ))
                # Update existing rows to set updated_at to created_at
                db.session.execute(text(
                    "UPDATE incomes SET updated_at = created_at WHERE updated_at IS NULL"
                ))
                db.session.commit()
                print("✓ Successfully added 'updated_at' column")
            else:
                print("✓ 'updated_at' column already exists")
            
            print("\n✓ Migration completed successfully!")
            
        except Exception as e:
            print(f"\n✗ Migration failed: {str(e)}")
            db.session.rollback()

if __name__ == '__main__':
    migrate_add_currency()
