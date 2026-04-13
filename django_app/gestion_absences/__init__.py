# Make oracledb work as cx_Oracle for Django 3.2
import sys
import datetime
import oracledb

oracledb.version = "8.3.0"

# Fix type compatibility issues between oracledb and Django 3.2
if not hasattr(oracledb, 'Binary') or not isinstance(oracledb.Binary, type):
    oracledb.Binary = bytes

# Replace oracledb.Date and Timestamp with actual types
# Django 3.2 calls isinstance(value, Database.Date) which requires a type, not a function
oracledb.Date = datetime.date
oracledb.Timestamp = datetime.datetime

sys.modules["cx_Oracle"] = oracledb
oracledb.init_oracle_client()

# Monkey-patch Django's Oracle backend to fix convert_datefield_value
# The original crashes because it uses isinstance() with DB-API Date which may not be a type
def _patch_oracle_backend():
    try:
        from django.db.backends.oracle import operations
        original_convert = operations.DatabaseOperations.convert_datefield_value

        def patched_convert_datefield_value(self, value, expression, connection):
            if value is None:
                return value
            if isinstance(value, datetime.datetime):
                return value.date()
            if isinstance(value, datetime.date):
                return value
            return value

        operations.DatabaseOperations.convert_datefield_value = patched_convert_datefield_value
    except Exception:
        pass

_patch_oracle_backend()
