CREATE OR REPLACE PROCEDURE pr_add_verter_check(new_checked_peer text, new_task_title text, new_state check_state, new_check_time time)
AS
$$
DECLARE
    new_check_id BIGSERIAL := 0;
BEGIN
    new_check_id = (SELECT checks.id
                    FROM p2p JOIN checks  ON p2p.check_id = checks.id
                    AND checks.task = new_task_title
                    AND checks.peer = new_checked_peer
                    ORDER BY p2p.check_time LIMIT 1);
    INSERT INTO verter (check_id, state, check_time)
    VALUES (new_check_id, new_state, new_check_time);
END;
$$ LANGUAGE plpgsql;