CREATE OR REPLACE FUNCTION fn_check_peers_two_of_three_task_done(
    task1 VARCHAR, task2 VARCHAR, task3 VARCHAR)
    RETURNS TABLE(peer VARCHAR)
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
        SELECT peer
        FROM checks
            LEFT JOIN p2p p ON checks.id = p.check_id
            LEFT JOIN verter v ON checks.id = v.check_id
        WHERE p.state = 'success' AND
              v.state IS NULL OR v.state = 'success'
        GROUP BY peer
        HAVING task1 = ANY(ARRAY_AGG(task))
            AND task2 = ANY(ARRAY_AGG(task))
            AND task3 != ALL(ARRAY_AGG(task));
END;
$$ LANGUAGE plpgsql;

--TEST
INSERT INTO peers VALUES ('dedelmir', '1999-02-08');
INSERT INTO peers VALUES ('drayl', '1999-05-05');
INSERT INTO checks VALUES (36, 'dedelmir', 'CPP1_s21_matrix+', '2022-02-08');
INSERT INTO checks VALUES (37, 'drayl', 'CPP1_s21_matrix+', '2022-05-05');
INSERT INTO checks VALUES (38, 'dedelmir', 'C2_SimpleBashUtils', '2022-02-08');
INSERT INTO checks VALUES (39, 'drayl', 'C2_SimpleBashUtils', '2022-05-05');
INSERT INTO p2p VALUES (80, 36, 'myregree', 'start', '13:00:00');
INSERT INTO p2p VALUES (81, 36, 'myregree', 'success', '13:00:00');
INSERT INTO p2p VALUES (82, 37, 'myregree', 'start', '13:00:00');
INSERT INTO p2p VALUES (83, 37, 'myregree', 'success', '13:00:00');
INSERT INTO p2p VALUES (84, 38, 'myregree', 'start', '13:00:00');
INSERT INTO p2p VALUES (85, 38, 'myregree', 'success', '13:00:00');
INSERT INTO p2p VALUES (86, 39, 'myregree', 'start', '13:00:00');
INSERT INTO p2p VALUES (87, 39, 'myregree', 'success', '13:00:00');
INSERT INTO checks VALUES (40, 'drayl', 'C3_s21_string+', '2022-05-05');
INSERT INTO p2p VALUES (88, 40, 'myregree', 'start', '13:00:00');
INSERT INTO p2p VALUES (89, 40, 'myregree', 'success', '13:00:00');
--INSERT INTO verter VALUES (70, 38, 'start', '13:00:00');
--INSERT INTO verter VALUES (71, 38, 'failure', '13:00:00');

SELECT * FROM fn_check_peers_two_of_three_task_done('CPP1_s21_matrix+', 'C2_SimpleBashUtils', 'C3_s21_string+');

DELETE FROM p2p WHERE id BETWEEN 80 AND 89;
DELETE FROM checks WHERE id BETWEEN 36 AND 40;
DELETE FROM peers WHERE nickname = 'drayl' OR nickname = 'dedelmir';
--DELETE FROM verter WHERE id BETWEEN 70 AND 71;