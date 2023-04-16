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


