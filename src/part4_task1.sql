CREATE OR REPLACE PROCEDURE proc_drop_tablename_tables()
AS $$
DECLARE
    rec record;
BEGIN
    FOR rec IN (SELECT * FROM information_schema.tables WHERE table_name SIMILAR TO 'tablename%')
    LOOP
        EXECUTE 'DROP TABLE ' ||  quote_ident(rec.table_name);
        RAISE INFO 'Dropped table: %', quote_ident(rec.table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- TEST
CREATE TABLE IF NOT EXISTS tablename_first();
CREATE TABLE IF NOT EXISTS tablename_second();
SELECT * FROM information_schema.tables WHERE table_name SIMILAR TO 'tablename%';
CALL proc_drop_tablename_tables();
SELECT * FROM information_schema.tables WHERE table_name SIMILAR TO 'tablename%';