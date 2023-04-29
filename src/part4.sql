/* 1) Create a stored procedure that, without destroying the database,
   destroys all those tables in the current database whose names begin
   with the phrase 'TableName' */

CREATE OR REPLACE PROCEDURE proc_drop_tablename_tables()
AS $$
DECLARE
    rec record;
BEGIN
    FOR rec IN (SELECT * FROM information_schema.tables
    WHERE table_catalog = (SELECT CURRENT_DATABASE())
        AND table_schema = (SELECT CURRENT_SCHEMA())
        AND table_type = 'BASE TABLE'
        AND table_name SIMILAR TO 'tablename%')
    LOOP
        EXECUTE 'DROP TABLE ' || QUOTE_IDENT(rec.table_name);
        RAISE INFO 'Dropped table: %', QUOTE_IDENT(rec.table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- TEST
CREATE TABLE IF NOT EXISTS tablename_first();
CREATE TABLE IF NOT EXISTS tablename_second();
SELECT * FROM information_schema.tables WHERE table_name SIMILAR TO 'tablename%';
CALL proc_drop_tablename_tables();
SELECT * FROM information_schema.tables WHERE table_name SIMILAR TO 'tablename%';


/* 2) Create a stored procedure with an output parameter that outputs
   a list of names and parameters of all scalar user's SQL functions
   in the current database. Do not output function names without
   parameters. The names and the list of parameters must be in one
   string. The output parameter returns the number of functions found */

CREATE OR REPLACE PROCEDURE proc_scalar_functions(OUT cnt NUMERIC)
AS $$
DECLARE
    rec RECORD;
    ref cursor for (SELECT ROW_NUMBER() OVER () as num, proname, proargnames FROM pg_proc
         WHERE proowner = (SELECT oid FROM pg_authid WHERE rolname = CURRENT_USER)
             AND prokind = 'f' AND proretset = FALSE
             AND prorettype != (SELECT oid FROM pg_type WHERE typname = 'void')
             AND proargnames IS NOT NULL);
    t TEXT DEFAULT '';
BEGIN
    cnt := 0;
    FOR rec IN ref LOOP
        cnt := cnt + 1;
        t := CONCAT(t, rec.proname, ' ', rec.proargnames, ', ');
    END LOOP;
    RAISE NOTICE 'Scalar user-defined functions: %', trim(TRAILING ', ' FROM t);
END;
$$ LANGUAGE plpgsql;

-- TEST
CREATE OR REPLACE FUNCTION fn_hello() RETURNS void AS $$  BEGIN END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_four() RETURNS INT AS $$  BEGIN RETURN 4; END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_sum(a NUMERIC, b NUMERIC) RETURNS NUMERIC AS $$  BEGIN RETURN a + b; END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_dif(a NUMERIC, b NUMERIC, c NUMERIC) RETURNS NUMERIC AS $$  BEGIN RETURN a - b - c; END; $$ LANGUAGE plpgsql;

DO $$
    DECLARE
        a NUMERIC;
    BEGIN
        CALL proc_scalar_functions(a);
        RAISE NOTICE 'RETURNS: %', a;
    END;
$$;

DROP FUNCTION IF EXISTS fn_hello(), fn_sum(a NUMERIC, b NUMERIC), fn_four(), fn_dif(a NUMERIC, b NUMERIC, c NUMERIC);


/* 3) Create a stored procedure with output parameter, which destroys
   all SQL DML triggers in the current database. The output parameter
   returns the number of destroyed triggers */

-- TASK PROCEDURE
CREATE OR REPLACE PROCEDURE proc_kill_all_triggers(a OUT INT) AS $$
DECLARE
    result INT;
    triggerName RECORD;
BEGIN
    FOR triggerName IN SELECT * FROM information_schema.triggers AS t
        WHERE t.trigger_schema = 'public'
        AND t.trigger_catalog = (SELECT current_database()) LOOP
            RAISE NOTICE 'Dropping trigger: % on table: %', triggerName.trigger_name, triggerName.event_object_table;
            EXECUTE 'DROP TRIGGER IF EXISTS ' || triggerName.trigger_name || ' ON ' || triggerName.event_object_table || ';';
    END LOOP;
    a := result;
END;
$$ LANGUAGE plpgsql;

-- PREPARE TRIGGER FOR TEST
CREATE OR REPLACE FUNCTION test_trigger_func() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
	RAISE NOTICE 'trigger ran';
	RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS test_trigger ON peers;
CREATE TRIGGER test_trigger
  BEFORE UPDATE ON peers
  FOR EACH ROW
  EXECUTE PROCEDURE test_trigger_func();

-- TESTING PROCEDURE
DO $$
DECLARE
    a INT;
BEGIN
    CALL proc_kill_all_triggers(a);
    RAISE NOTICE '%', a;
END;$$;

-- ASSERT RESULT
SELECT * FROM information_schema.triggers AS t
        WHERE t.trigger_schema = 'public'
        AND t.trigger_catalog = (SELECT current_database());


/* 4) Create a stored procedure with an input parameter that outputs names
   and descriptions of object types (only stored procedures and scalar
   functions) that have a string specified by the procedure parameter. */

CREATE OR REPLACE PROCEDURE proc_scalar_functions_and_procedures_contains_str(IN str TEXT)
AS $$
DECLARE
    rec RECORD;
    ref CURSOR FOR (
        SELECT proname, description
        FROM pg_proc LEFT JOIN pg_description pd ON oid=objoid
        WHERE ((prokind = 'f' AND proretset = FALSE
                AND prorettype != (SELECT oid FROM pg_type WHERE typname = 'void'))
           OR prokind = 'p')
          AND (upper(proname) SIMILAR TO CONCAT('%', upper(str), '%')
                   OR upper(description) SIMILAR TO CONCAT('%', upper(str), '%')));
BEGIN
    FOR rec IN ref LOOP
        RAISE NOTICE '% description: %', rec.proname, rec.description;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- TEST
CALL proc_scalar_functions_and_procedures_contains_str('rou');

