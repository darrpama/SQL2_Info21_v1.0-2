CREATE OR REPLACE PROCEDURE pr_add_p2p_check(new_checked_peer text, new_checking_peer text, new_task_title text, new_state check_state, new_check_time time)
AS
$$
DECLARE
    new_check_id BIGSERIAL := 0;
BEGIN
    IF new_state = 'start'
    THEN
        new_check_id = (SELECT max(id) FROM checks) + 1;
        INSERT INTO checks (id, peer, task, check_date)
        VALUES (new_check_id, new_checked_peer, new_task_title, (SELECT CURRENT_DATE));
    ELSE
        new_check_id = (SELECT checks.id FROM p2p
                    INNER JOIN checks ON checks.id = p2p.check_id
                    WHERE peer = $1
                    AND p2p.checking_peer = $2
                    AND task = $3
                    ORDER BY checks.id DESC LIMIT 1);
    END IF;
    INSERT INTO p2p (check_id, checking_peer, state, check_time)
    VALUES (new_check_id, new_checking_peer, new_state, new_check_time);
END;
$$ LANGUAGE plpgsql;