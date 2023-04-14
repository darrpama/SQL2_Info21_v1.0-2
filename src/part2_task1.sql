CREATE OR REPLACE PROCEDURE pr_add_p2p_check(new_checked_peer text, new_checking_peer text, new_task_title text, new_state check_state, new_check_time time)
AS $$
    DECLARE
        new_check_id BIGINT := 0;
        new_p2p_id BIGINT := 0;
    BEGIN
        IF new_state = 'start' THEN
            IF ((SELECT count(*) FROM p2p
                JOIN checks ON p2p.check_id = checks.id
                WHERE p2p.checking_peer = new_checking_peer
                AND checks.peer = new_checked_peer
                AND checks.task = new_task_title) = 1)
            THEN
                RAISE EXCEPTION 'Exception';
            ELSE
                new_check_id = (SELECT max(id) + 1 FROM checks);
                INSERT INTO checks (id, peer, task, check_date)
                VALUES (new_check_id, new_checked_peer, new_task_title, now());

                new_p2p_id = (SELECT max(id) + 1 FROM p2p);
                INSERT INTO p2p (id, check_id, checking_peer, state, check_time)
                VALUES (new_p2p_id, new_check_id - 1, new_checking_peer, new_state, new_check_time);
            END IF;
        ELSE
            new_check_id = (SELECT checks.id FROM p2p
                            INNER JOIN checks ON checks.id = p2p.check_id
                            WHERE peer = new_checked_peer
                            AND p2p.checking_peer = new_checking_peer
                            AND task = new_task_title
                            ORDER BY checks.id DESC LIMIT 1);
            INSERT INTO p2p (check_id, checking_peer, state, check_time)
            VALUES (new_check_id, new_checking_peer, new_state, new_check_time);
        END IF;
    END
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------

CALL pr_add_p2p_check('darrpama', 'myregree', 'C7_SmartCalc_v1.0', 'start'::check_state, '15:30:01')