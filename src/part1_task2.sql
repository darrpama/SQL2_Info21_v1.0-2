---------------------------------------------------------------------------------------------
-- IMPORT FROM CSV
---------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE import_from_csv(
    table_name varchar,
    global_path varchar,
    delimiter varchar
) AS $$
    BEGIN
        EXECUTE format(
            'COPY %s FROM %L WITH DELIMITER %L CSV HEADER',
            table_name,
            global_path,
            delimiter
        );
    END
$$ LANGUAGE plpgsql;

---- TESTING SCRIPTS
TRUNCATE peers CASCADE;
CALL import_from_csv ('peers', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/peers.csv', ',');

---------------------------------------------------------------------------------------------
-- EXPORT TO CSV
---------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE export_to_csv(
    table_name varchar,
    global_path varchar,
    delimiter varchar
) AS $$
    BEGIN
--         Copy (Select * From $1) To $2 With CSV DELIMITER $3 HEADER;
        EXECUTE format(
            'COPY %s TO %L WITH CSV DELIMITER %L HEADER',
            table_name,
            global_path,
            delimiter
        );
    END
$$ LANGUAGE plpgsql;

-- -- TESTING SCRIPTS
TRUNCATE peers CASCADE;
INSERT INTO peers VALUES ('myregree', '1987.10.19');
INSERT INTO peers VALUES ('darrpama', '1988.11.20');
CALL export_to_csv ('peers', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/peers.csv', ',');

