CREATE OR REPLACE PROCEDURE proc_scalar_functions_and_procedures_contains_str(IN str TEXT)
AS $$
DECLARE
    rec RECORD;
    ref cursor for (SELECT proname, prosrc FROM pg_proc
         WHERE ((prokind = 'f' AND proretset = FALSE
                 AND prorettype != (SELECT oid FROM pg_type WHERE typname = 'void'))
             OR prokind = 'p') AND upper(prosrc) SIMILAR TO CONCAT('%', upper(str), '%'));
BEGIN
    FOR rec IN ref LOOP
        RAISE NOTICE '==================== % description ====================', rec.proname;
        RAISE NOTICE '%', rec.prosrc;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- TEST
CREATE OR REPLACE FUNCTION fn_sum(a NUMERIC, b NUMERIC) RETURNS NUMERIC AS $$  BEGIN RETURN a + b; END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_dif(a NUMERIC, b NUMERIC, c NUMERIC) RETURNS NUMERIC AS $$  BEGIN RETURN a - b - c; END; $$ LANGUAGE plpgsql;

CALL proc_scalar_functions_and_procedures_contains_str('\+');

DROP FUNCTION IF EXISTS fn_sum(a NUMERIC, b NUMERIC), fn_dif(a NUMERIC, b NUMERIC, c NUMERIC);