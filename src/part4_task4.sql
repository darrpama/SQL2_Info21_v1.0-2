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