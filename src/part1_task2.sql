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
CALL import_from_csv ('peers', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/01-init_peers.csv', ',');

TRUNCATE tasks CASCADE;
CALL import_from_csv ('tasks', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/02-init_tasks.csv', ',');

TRUNCATE checks CASCADE;
CALL import_from_csv ('checks', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/03-init_checks.csv', ',');

TRUNCATE p2p CASCADE;
CALL import_from_csv ('p2p', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/04-init_p2p.csv', ',');

TRUNCATE verter CASCADE;
CALL import_from_csv ('verter', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/05-init_verter.csv', ',');

-- SELECT checking_peer, peer FROM checks JOIN p2p ON checks.id = p2p.check_id WHERE state != 'start' and state != 'failure' ORDER BY checking_peer, peer;
-- SELECT checking_peer, peer FROM checks JOIN p2p ON checks.id = p2p.check_id WHERE state != 'start' ORDER BY checking_peer, peer;

TRUNCATE transferred_points CASCADE;
CALL import_from_csv ('transferred_points', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/06-init_transferred_points.csv', ',');

TRUNCATE friends CASCADE;
CALL import_from_csv ('friends', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/07-init_friends.csv', ',');

TRUNCATE recommendations CASCADE;
CALL import_from_csv ('recommendations', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/08-init_recommendations.csv', ',');

TRUNCATE xp CASCADE;
CALL import_from_csv ('xp', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/09-init_xp.csv', ',');

TRUNCATE time_tracking CASCADE;
CALL import_from_csv ('time_tracking', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-0/src/csv/10-init_time_tracking.csv', ',');

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

