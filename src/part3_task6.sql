CREATE OR REPLACE FUNCTION fn_mostly_checked_tasks_by_days ()
    RETURNS TABLE (
        Day DATE,
        Task VARCHAR
    )
    LANGUAGE plpgsql
AS $$
    #variable_conflict use_column
BEGIN
    RETURN QUERY
        WITH t AS (SELECT check_date, task, COUNT(task) as cnt
                   FROM checks
                   GROUP BY check_date, task)

        SELECT t.check_date as day, task
        FROM t
            LEFT JOIN (
                SELECT check_date, MAX(cnt) as m
                FROM t
                GROUP BY check_date
            ) t2 on t.check_date = t2.check_date
        WHERE m = cnt;
END; $$;


-- TEST
SELECT * FROM fn_mostly_checked_tasks_by_days();

-- PREPARE TEST DATA
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- 01-01
call pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils','start', '20:25');
call pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils','success', '20:45');
call pr_add_verter_check('darrpama', 'C2_SimpleBashUtils','start', '21:05');
call pr_add_verter_check('darrpama', 'C2_SimpleBashUtils','success', '21:06');

call pr_add_p2p_check('myregree', 'darrpama', 'C2_SimpleBashUtils','start', '20:25');
call pr_add_p2p_check('myregree', 'darrpama', 'C2_SimpleBashUtils','success', '20:45');
call pr_add_verter_check('myregree', 'C2_SimpleBashUtils','start', '21:05');
call pr_add_verter_check('myregree', 'C2_SimpleBashUtils','success', '21:06');

call pr_add_p2p_check('darrpama', 'myregree', 'C3_s21_string+','start', '20:25');
call pr_add_p2p_check('darrpama', 'myregree', 'C3_s21_string+','success', '20:45');
call pr_add_verter_check('darrpama', 'C3_s21_string+','start', '21:05');
call pr_add_verter_check('darrpama', 'C3_s21_string+','success', '21:06');

call pr_add_p2p_check('myregree', 'darrpama', 'C3_s21_string+','start', '20:25');
call pr_add_p2p_check('myregree', 'darrpama', 'C3_s21_string+','success', '20:45');
call pr_add_verter_check('myregree', 'C3_s21_string+','start', '21:05');
call pr_add_verter_check('myregree', 'C3_s21_string+','success', '21:06');

call pr_add_p2p_check('maddiega', 'darrpama', 'C3_s21_string+','start', '20:25');
call pr_add_p2p_check('maddiega', 'darrpama', 'C3_s21_string+','success', '20:45');
call pr_add_verter_check('maddiega', 'C3_s21_string+','start', '21:05');
call pr_add_verter_check('maddiega', 'C3_s21_string+','success', '21:06');

INSERT INTO checks(peer, task, check_date) VALUES ('darrpama', 'C2_SimpleBashUtils', '2023-01-02 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (5, 'myregree', 'start', '2023-01-02 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (5, 'myregree', 'success', '2023-01-02 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (5, 'start', '2023-01-01 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (5, 'success', '2023-01-01 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (5, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C3_s21_string+', '2023-01-02 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (6, 'darrpama', 'start', '2023-01-02 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (6, 'darrpama', 'success', '2023-01-02 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (6, 'start', '2023-01-02 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (6, 'success', '2023-01-02 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (6, 250);

