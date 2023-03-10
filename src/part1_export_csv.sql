CREATE OR REPLACE PROCEDURE export_to_csv(table_name text, global_path text, delimiter text)
AS
$$
BEGIN
    COPY $1 TO $2 WITH CSV DELIMITER $3 HEADER;
END;
$$ LANGUAGE plpgsql;

CALL export_to_csv('', '', '');