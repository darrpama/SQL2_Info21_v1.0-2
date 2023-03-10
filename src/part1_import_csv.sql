-- TRUNCATE ... CASCADE;    -- delete data from some table to import

CREATE OR REPLACE PROCEDURE import_from_csv(table_name text, global_path text, delimiter text)
AS
$$
BEGIN
    COPY $2 TO $1 WITH CSV DELIMITER $3 HEADER;
END;
$$ LANGUAGE plpgsql;

-- CALL import_from_csv('', '', '');
