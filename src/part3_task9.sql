CREATE OR REPLACE FUNCTION fn_percent_by_blocks(block1 VARCHAR, block2 VARCHAR)
    RETURNS TABLE (StartedBlock1 INTEGER, StartedBlock2 INTEGER, StartedBothBlocks INTEGER, DidntStartAnyBlock INTEGER)
AS $$
    DECLARE cnt INTEGER := (SELECT COUNT(nickname) FROM peers);
BEGIN
    RETURN QUERY
        WITH b1 AS (SELECT DISTINCT peer FROM checks WHERE task SIMILAR TO CONCAT(block1, '[0-9]%')),
             b2 AS (SELECT DISTINCT peer FROM checks WHERE task SIMILAR TO CONCAT(block2, '[0-9]%')),
             b3 AS ((SELECT peer FROM b1) INTERSECT (SELECT peer FROM b2)),
             b4 AS ((SELECT nickname AS peer FROM peers) EXCEPT ((SELECT peer FROM b1) UNION (SELECT peer FROM b2)))
        SELECT * FROM
            (SELECT (COUNT(peer) * 100.0 / cnt)::INTEGER FROM b1) AS b1perc CROSS JOIN
            (SELECT (COUNT(peer) * 100.0 / cnt)::INTEGER FROM b2) AS b2perc CROSS JOIN
            (SELECT (COUNT(peer) * 100.0 / cnt)::INTEGER FROM b3) AS b3perc CROSS JOIN
            (SELECT (COUNT(peer) * 100.0 / cnt)::INTEGER FROM b4) AS b4perc;
END;
$$ LANGUAGE plpgsql;


-- TEST
INSERT INTO checks VALUES (36, 'myregree', 'CPP1_s21_matrix+', '2023-02-01');
INSERT INTO peers VALUES ('dedelmir', '1999-02-08');
INSERT INTO checks VALUES (37, 'dedelmir', 'CPP1_s21_matrix+', '2023-02-01');
--INSERT INTO checks VALUES (38, 'dedelmir', 'C2_SimpleBashUtils', '2023-02-01');
INSERT INTO peers VALUES ('drayl', '1999-05-28');

SELECT * FROM fn_percent_by_blocks('C', 'CPP');

DELETE FROM checks WHERE id = 36;
DELETE FROM checks WHERE id = 37;
--DELETE FROM checks WHERE id = 38;
DELETE FROM peers VALUES WHERE nickname = 'dedelmir';
DELETE FROM peers VALUES WHERE nickname = 'drayl';