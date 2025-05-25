# MySQL Schema Case Sensitivity Fix

## Problem Description

The DuckDB MySQL scanner had an issue where schema names with different cases could cause table lookups to fail. This occurred because:

1. MySQL allows case-sensitive schema names depending on the `lower_case_table_names` setting and file system
2. DuckDB stores schema names exactly as returned by `information_schema.schemata`
3. DuckDB allows case-insensitive schema lookup internally
4. But when querying `information_schema.columns` for table metadata, the comparison was case-sensitive
5. This caused tables to not show up when the schema was referenced with different case

## Root Cause

The issue was in queries to MySQL's `information_schema` tables where `table_schema` comparisons were case-sensitive on case-sensitive file systems when `lower_case_table_names=0`. According to MySQL documentation:

> String columns in INFORMATION_SCHEMA tables have a collation of utf8_general_ci, which is case-insensitive. However, for values that correspond to objects that are represented in the file system, such as databases and tables, searches in INFORMATION_SCHEMA string columns can be case-sensitive or case-insensitive, depending on the characteristics of the underlying file system and the value of the lower_case_table_names system variable.

## Solution

The fix adds `COLLATE utf8_general_ci` to all `table_schema` comparisons in `information_schema` queries to ensure case-insensitive matching regardless of the MySQL server configuration.

## Files Changed

### 1. `src/storage/mysql_table_set.cpp`

**LoadEntries function:**
```sql
-- Before:
WHERE table_schema=${SCHEMA_NAME}

-- After:
WHERE table_schema COLLATE utf8_general_ci = ${SCHEMA_NAME}
```

**GetTableInfoQuery function:**
```sql
-- Before:
WHERE table_schema=${SCHEMA_NAME} AND table_name=${TABLE_NAME}

-- After:
WHERE table_schema COLLATE utf8_general_ci = ${SCHEMA_NAME} AND table_name=${TABLE_NAME}
```

### 2. `src/storage/mysql_catalog.cpp`

**GetDatabaseSize function:**
```sql
-- Before:
WHERE table_schema = ${SCHEMA_NAME}

-- After:
WHERE table_schema COLLATE utf8_general_ci = ${SCHEMA_NAME}
```

### 3. `src/storage/mysql_index_set.cpp`

**LoadEntries function:**
```sql
-- Before:
WHERE TABLE_SCHEMA = 'mysqlscanner'

-- After:
WHERE TABLE_SCHEMA COLLATE utf8_general_ci = ${SCHEMA_NAME}
```

Note: This also fixed a bug where the schema name was hardcoded instead of using the actual schema.

## Test Case

The fix is verified by the test `test/sql/test_case_sensitive_schema.test` which:

1. Creates a schema with specific case (`TestSchema`)
2. Creates a table in that schema
3. Verifies that queries work with different case variations:
   - `TestSchema.test_table` (exact case)
   - `testschema.test_table` (lowercase)
   - `TESTSCHEMA.test_table` (uppercase)
4. Verifies that `information_schema` queries work regardless of case

## Impact

This fix ensures that:
- Schema lookups work consistently regardless of MySQL's `lower_case_table_names` setting
- Tables are properly discovered even when schema names are referenced with different case
- The behavior is consistent across different MySQL configurations and file systems
- No breaking changes to existing functionality

## MySQL Documentation References

- [MySQL 8.4 Identifier Case Sensitivity](https://dev.mysql.com/doc/refman/8.4/en/identifier-case-sensitivity.html)
- [Using Collation in INFORMATION_SCHEMA Searches](https://dev.mysql.com/doc/refman/5.7/en/charset-collation-information-schema.html) 