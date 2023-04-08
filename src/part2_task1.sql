CREATE OR REPLACE PROCEDURE pr_add_p2p_check(
    new_checked_peer  text,
    new_checking_peer text,
    new_task_title    text,
    new_state         check_state,
    new_check_time    time
) AS
$$
DECLARE
    new_check_id BIGINT := 0;
    new_p2p_id BIGINT := 0;
BEGIN
    IF new_state = 'start'
    THEN
        IF ((SELECT count(*) FROM p2p
            JOIN checks ON p2p.check_id = checks.id
            WHERE p2p.checking_peer = new_checking_peer
            AND checks.peer = new_checked_peer
            AND checks.task = new_task_title) = TRUE)
        THEN
            RAISE EXCEPTION 'Невозможно добавить проверку для данных пиров, так как у них есть незавершённая проверка';
        ELSE
            SELECT @new_check_id = (SELECT max(id) FROM checks) + 1;
            INSERT INTO checks (id, peer, task, check_date)
            VALUES (new_check_id, new_checked_peer, new_task_title, now());

            SELECT @new_p2p_id = (SELECT max(id) FROM p2p) + 1;
            INSERT INTO p2p (id, check_id, checking_peer, state, check_time)
            VALUES (new_p2p_id, new_check_id - 1, checking_peer, state, check_time);
        END IF;
    ELSE
        new_check_id = (SELECT checks.id FROM p2p
                    INNER JOIN checks ON checks.id = p2p.check_id
                    WHERE peer = $1
                    AND p2p.checking_peer = $2
                    AND task = $3
                    ORDER BY checks.id DESC LIMIT 1);
        INSERT INTO p2p (check_id, checking_peer, state, check_time)
        VALUES (new_check_id, new_checking_peer, new_state, new_check_time);
    END IF;
END;
$$ LANGUAGE plpgsql;

CALL pr_add_p2p_check('darrpama', 'myregree', 'C7_SmartCalc_v1.0', 'start', '15:30:01')
