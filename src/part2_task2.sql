CREATE OR REPLACE PROCEDURE pr_add_verter_check(new_checked_peer text, new_task_title text, new_state check_state, new_check_time time)
AS
$$
    DECLARE
        new_check_id BIGINT := 0;
    BEGIN
        IF (new_state = 'start')
        THEN
            IF ((SELECT max(p2p.time) FROM p2p
                JOIN checks c on p2p.check_id = c.id
                WHERE c.peer = new_checked_peer
                  AND c.task = new_task_title
                  AND p2p.state = 'success') IS NULL)
            THEN
                RAISE EXCEPTION 'P2P must be success';
            ELSE
                new_check_id = (SELECT DISTINCT checks.id FROM p2p
                                        JOIN checks ON p2p.check_id = checks.id
                                        AND checks.task = new_task_title
                                        AND checks.peer = new_checked_peer
                                        AND p2p.state = 'success'
                                        ORDER BY p2p.check_time LIMIT 1);
                INSERT INTO verter (check_id, state, check_time)
                VALUES (new_check_id, new_state, new_check_time);
            END IF;
        ELSE
            new_check_id = (SELECT check_id FROM verter
                                    GROUP BY check_id
                                    HAVING count(*) % 2 = 1);
            INSERT INTO verter (check_id, state, check_time)
            VALUES (new_check_id, new_state, new_check_time);
        END IF;
    END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------

CALL pr_add_verter_check('maddiega', 'C7_SmartCalc_v1.0', 'success', '22:50:00')
