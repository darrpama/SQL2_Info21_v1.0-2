CREATE OR REPLACE FUNCTION fn_mostly_checked_tasks_by_days ()
    RETURNS TABLE (
        Day date,
        Task varchar
    )
    language plpgsql
AS $$
BEGIN
    RETURN QUERY
        WITH day_max AS (
            SELECT DISTINCT ON (t.check_date) t.check_date, tasks_count
            FROM (
                SELECT count(c2.task) as tasks_count, check_date
                FROM checks as c2
                GROUP BY c2.task, c2.check_date
            ) as t
            ORDER BY t.check_date, tasks_count DESC
        )

        SELECT
            t1.check_date as Day,
            t1.task as Task
        FROM (
            SELECT c1.task, count(c1.task) as tasks_count, c1.check_date
            FROM checks as c1
            GROUP BY c1.task, c1.check_date
        ) t1
        INNER JOIN day_max t2
            ON t1.check_date = t2.check_date
            AND t1.tasks_count = t2.tasks_count
        ORDER BY Day;
END; $$;


-- TEST
SELECT * FROM fn_mostly_checked_tasks_by_days();

-- PREPARE TEST DATA
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- 01-01
INSERT INTO checks(peer, task, check_date) VALUES ('darrpama', 'C2_SimpleBashUtils', '2023-01-01 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'myregree', 'start', '2023-01-01 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'myregree', 'success', '2023-01-01 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'start', '2023-01-01 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'success', '2023-01-01 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (1, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-01-01 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (2, 'darrpama', 'start', '2023-01-01 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (2, 'darrpama', 'success', '2023-01-01 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (2, 'start', '2023-01-01 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (2, 'success', '2023-01-01 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (2, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C3_s21_string+', '2023-01-01 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (3, 'darrpama', 'start', '2023-01-01 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (3, 'darrpama', 'success', '2023-01-01 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (3, 'start', '2023-01-01 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (3, 'success', '2023-01-01 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (3, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C3_s21_string+', '2023-01-01 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (10, 'darrpama', 'start', '2023-01-01 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (10, 'darrpama', 'success', '2023-01-01 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (10, 'start', '2023-01-01 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (10, 'success', '2023-01-01 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (10, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C4_s21_math', '2023-01-01 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (11, 'darrpama', 'start', '2023-01-01 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (11, 'darrpama', 'success', '2023-01-01 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (11, 'start', '2023-01-01 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (11, 'success', '2023-01-01 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (11, 250);

-- 01-02
INSERT INTO checks(peer, task, check_date) VALUES ('darrpama', 'C2_SimpleBashUtils', '2023-01-02 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (4, 'myregree', 'start', '2023-01-02 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (4, 'myregree', 'success', '2023-01-02 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (4, 'start', '2023-01-01 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (4, 'success', '2023-01-01 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (4, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C3_s21_string+', '2023-01-02 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (5, 'darrpama', 'start', '2023-01-02 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (5, 'darrpama', 'success', '2023-01-02 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (5, 'start', '2023-01-02 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (5, 'success', '2023-01-02 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (5, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C3_s21_string+', '2023-01-02 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (6, 'darrpama', 'start', '2023-01-02 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (6, 'darrpama', 'success', '2023-01-02 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (6, 'start', '2023-01-02 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (6, 'success', '2023-01-02 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (6, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C4_s21_math', '2023-01-02 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (7, 'darrpama', 'start', '2023-01-02 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (7, 'darrpama', 'success', '2023-01-02 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (7, 'start', '2023-01-02 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (7, 'success', '2023-01-02 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (7, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C4_s21_math', '2023-01-02 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (8, 'darrpama', 'start', '2023-01-02 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (8, 'darrpama', 'success', '2023-01-02 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (8, 'start', '2023-01-02 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (8, 'success', '2023-01-02 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (8, 250);

INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C4_s21_math', '2023-01-02 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (9, 'darrpama', 'start', '2023-01-02 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (9, 'darrpama', 'success', '2023-01-02 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (9, 'start', '2023-01-02 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (9, 'success', '2023-01-02 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (9, 250);
