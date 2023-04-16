CREATE OR REPLACE FUNCTION fn_birthday_checks_percentage()
    RETURNS TABLE(SuccessfulChecks INTEGER, UnsuccessfulChecks INTEGER)
AS $$
    BEGIN
        RETURN QUERY
            WITH
                birthday_checks AS (
                    SELECT peer, state FROM checks
                        LEFT JOIN peers p ON checks.peer = p.nickname
                        LEFT JOIN p2p p2p2 ON checks.id = p2p2.check_id
                    WHERE to_char(check_date, 'MM-DD') = to_char(birthday, 'MM-DD')
                        AND state IS NOT NULL AND state != 'start'),
                cnt AS (SELECT COUNT(DISTINCT peer) FROM birthday_checks)
        SELECT * FROM
            (SELECT (COUNT(DISTINCT peer) * 100 / (SELECT * FROM cnt))::INTEGER FROM birthday_checks WHERE state = 'success') as s CROSS JOIN
            (SELECT (COUNT(DISTINCT peer) * 100 / (SELECT * FROM cnt))::INTEGER FROM birthday_checks WHERE state = 'failure') as f;
    END;
$$ LANGUAGE plpgsql;

--TEST
INSERT INTO peers VALUES ('dedelmir', '1999-02-08');
INSERT INTO peers VALUES ('drayl', '1999-05-05');
INSERT INTO checks VALUES (36, 'dedelmir', 'C2_SimpleBashUtils', '2022-02-08');
INSERT INTO checks VALUES (37, 'drayl', 'C2_SimpleBashUtils', '2022-05-05');
INSERT INTO p2p VALUES (80, 36, 'myregree', 'start', '13:00:00');
INSERT INTO p2p VALUES (81, 36, 'myregree', 'failure', '13:00:00');
INSERT INTO p2p VALUES (82, 37, 'myregree', 'start', '13:00:00');
INSERT INTO p2p VALUES (83, 37, 'myregree', 'success', '13:00:00');
--INSERT INTO peers VALUES ('gabriela', '1999-07-05');
--INSERT INTO checks VALUES (38, 'gabriela', 'C2_SimpleBashUtils', '2022-07-05');
--INSERT INTO p2p VALUES (84, 38, 'myregree', 'start', '13:00:00');
--INSERT INTO p2p VALUES (85, 38, 'myregree', 'success', '13:00:00');

--INSERT INTO checks VALUES (39, 'dedelmir', 'C2_SimpleBashUtils', '2022-02-08');
--INSERT INTO p2p VALUES (86, 39, 'myregree', 'start', '13:00:00');
--INSERT INTO p2p VALUES (87, 39, 'myregree', 'success', '13:00:00');

SELECT * FROM fn_birthday_checks_percentage();

DELETE FROM p2p WHERE id BETWEEN 80 AND 87;
DELETE FROM checks WHERE id BETWEEN 36 AND 39;
DELETE FROM peers WHERE nickname = 'drayl' OR nickname = 'dedelmir' OR nickname = 'gabriela';