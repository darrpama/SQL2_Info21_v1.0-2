CREATE OR REPLACE PROCEDURE proc_scalar_functions(OUT cnt NUMERIC)
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN (SELECT proname, proargnames FROM pg_proc
                WHERE proowner = (SELECT oid FROM pg_authid WHERE rolname = CURRENT_USER)
                    AND prokind = 'f' AND proretset = FALSE
                    AND prorettype != (SELECT oid FROM pg_type WHERE typname = 'void')
                    AND proargnames IS NOT NULL)
    LOOP
        RAISE NOTICE 'Name: %, args: %', rec.proname, rec.proargnames;
    END LOOP;
    cnt := (SELECT COUNT(proname) FROM pg_proc
            WHERE proowner = (SELECT oid FROM pg_authid WHERE rolname = CURRENT_USER)
                AND prokind = 'f' AND proretset = FALSE
                AND prorettype != (SELECT oid FROM pg_type WHERE typname = 'void')
                AND proargnames IS NOT NULL);
END;
$$ LANGUAGE plpgsql;


-- TEST
CREATE OR REPLACE FUNCTION fn_hello() RETURNS void AS $$  BEGIN END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_four() RETURNS INT AS $$  BEGIN RETURN 4; END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_sum(a NUMERIC, b NUMERIC) RETURNS NUMERIC AS $$  BEGIN RETURN a + b; END; $$ LANGUAGE plpgsql;

DO $$
    DECLARE
        a NUMERIC;
    BEGIN
        CALL proc_scalar_functions(a);
        RAISE NOTICE 'RETURNS: %', a;
    END;
$$;

