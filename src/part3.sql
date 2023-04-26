/* 1) Write a function that returns the TransferredPoints table in a more
   human-readable form.

   Peer's nickname 1, Peer's nickname 2, number of transferred peer points.
   The number is negative if peer 2 received more points from peer 1. */

CREATE OR REPLACE FUNCTION human_readable_transferredPoints()
    RETURNS TABLE (
        peer1 varchar,
        peer2 varchar,
        pointsAmount bigint
    )
    language plpgsql
AS $$
DECLARE var_r record;
BEGIN
    RETURN QUERY
    SELECT checking_peer, checked_peer, point_sum FROM (
        SELECT DISTINCT ON (pair) *,
            CASE WHEN checking_peer > checked_peer
                THEN (checking_peer, checked_peer)
                ELSE (checked_peer, checking_peer)
            END AS pair
        FROM (
            SELECT
                tp1.checking_peer,
                tp1.checked_peer,
                tp1.points_amount - COALESCE(tp2.points_amount, 0) AS point_sum
            FROM
                transferred_points tp1
            LEFT JOIN transferred_points tp2
                ON tp1.checking_peer = tp2.checked_peer
                AND tp1.checked_peer = tp2.checking_peer
            ORDER BY tp1.id
        ) as calculated
        ORDER BY pair
    ) AS data
ORDER BY checking_peer;
END; $$;

SELECT * FROM human_readable_transferredPoints();

/* 2) Write a function that returns a table of the following form:
   user name, name of the checked task, number of XP received.

   Include in the table only tasks that have successfully passed the check
   (according to the Checks table). One task can be completed successfully
   several times. In this case, include all successful checks in the table. */

CREATE OR REPLACE FUNCTION fnc_get_peers_success_tasks_with_xp()
    RETURNS TABLE (
        Peer varchar,
        Task varchar,
        XP bigint
    ) language plpgsql AS
$$
    BEGIN
        RETURN QUERY
            SELECT c.peer, c.task, x.xp_amount FROM checks AS c
                INNER JOIN xp x on c.id = x.check_id;
    END;
$$;

SELECT * FROM fnc_get_peers_success_tasks_with_xp();

/* 3) Write a function that finds the peers who have not left campus for the
   whole day.

   Function parameters: day, for example 12.05.2022.
   The function returns only a list of peers. */

CREATE OR REPLACE FUNCTION fn_get_peers_without_break_during_the_day(looking_date date)
    RETURNS TABLE (peer varchar)
AS $$
BEGIN
    RETURN QUERY
    SELECT states_count.peer FROM (
        SELECT tt.peer, count(state)
        FROM time_tracking tt
        WHERE date = looking_date
        GROUP BY tt.peer, state
    ) AS states_count
    WHERE states_count.count = 1
    GROUP BY states_count.peer;
END;
$$ language plpgsql;

SELECT * FROM fn_get_peers_without_break_during_the_day('2023-04-08');

/* 4) Calculate the change in the number of peer points of each peer using
   the TransferredPoints table.

   Output the result sorted by the change in the number of points.
   Output format: peer's nickname, change in the number of peer points. */

CREATE OR REPLACE FUNCTION fn_count_peer_points_changes_by_transferredPoints()
    RETURNS TABLE (
        Peer varchar,
        PointsChange numeric
    )
    language plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        checking.peer,
        (income - outcome) as points
    FROM (
        SELECT
            tp1.checking_peer as peer,
            sum(tp1.points_amount) as income
        FROM transferred_points tp1
        GROUP BY tp1.checking_peer
    ) AS checking
        JOIN (
            SELECT
                tp1.checked_peer as peer,
                sum(tp1.points_amount) as outcome
            FROM transferred_points tp1
            GROUP BY tp1.checked_peer
        ) AS checked ON checking.peer = checked.peer
    ORDER BY points DESC;
END; $$;

SELECT * FROM fn_count_peer_points_changes_by_transferredPoints();

/* 5) Calculate the change in the number of peer points of each peer using
   the table returned by the first function from Part 3

   Output the result sorted by the change in the number of points.
   Output format: peer's nickname, change in the number of peer points */

CREATE OR REPLACE FUNCTION fn_count_peer_points_changes_by_human_readable_func ()
    RETURNS TABLE (
        Peer varchar,
        PointsChange numeric
    )
    language plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT peerlist.peer, sum(pointsamount) s
    FROM (
        (SELECT peer1 as peer, pointsamount FROM human_readable_transferredPoints() t1)
        UNION ALL
        (SELECT peer2 as peer, (pointsamount * -1) FROM human_readable_transferredPoints() t1)
    ) as peerlist
    GROUP BY peerlist.peer
    ORDER BY s DESC;
END; $$;

SELECT * FROM fn_count_peer_points_changes_by_human_readable_func();

/* 6) Find the most frequently checked task for each day

   If there is the same number of checks for some tasks in a certain day,
   output all of them.
   Output format: day, task name */

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

SELECT * FROM fn_mostly_checked_tasks_by_days();

/* 7) Find all peers who have completed the whole given block of tasks and
   the completion date of the last task

   Procedure parameters: name of the block, for example “CPP”.
   The result is sorted by the date of completion.
   Output format: peer's name, date of completion of the block (i.e. the last
   completed task from that block) */

CREATE OR REPLACE FUNCTION fn_get_peers_finished_block(block VARCHAR)
    RETURNS TABLE(peer VARCHAR, date DATE)
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
        WITH successful_checks AS
            (SELECT DISTINCT peer, task,
                 FIRST_VALUE(check_date) OVER (PARTITION BY peer, task ORDER BY check_date) as date
             FROM (SELECT * FROM checks WHERE task SIMILAR TO CONCAT(block, '[0-9]%')) as c
                   LEFT JOIN xp ON c.id = xp.check_id
            WHERE xp.xp_amount IS NOT NULL)
        SELECT peer, MAX(date) as date FROM successful_checks GROUP BY peer
        HAVING COUNT(task) = (SELECT COUNT(title) FROM tasks WHERE title SIMILAR TO CONCAT(block, '[0-9]%'));
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_get_peers_finished_block('C');

/* 8) Determine which peer each student should go to for a check.

   You should determine it according to the recommendations of the peer's
   friends, i.e. you need to find the peer with the greatest number of friends
   who recommend to be checked by him.
   Output format: peer's nickname, nickname of the checker found */

CREATE OR REPLACE FUNCTION fn_wich_peer_should_peer_be_evaluated()
    RETURNS TABLE (peer VARCHAR, RecommendedPeer VARCHAR)
AS $$
BEGIN
    RETURN QUERY
        WITH frend_union AS (SELECT peer1, peer2 FROM friends
                             UNION SELECT peer2 AS peer1, peer1 AS peer2 FROM friends)
        SELECT DISTINCT peer1 AS peer, FIRST_VALUE(recommended_peer) OVER (PARTITION BY peer1 ORDER BY rec_cnt DESC)
        FROM (SELECT u.peer1, r.recommended_peer, COUNT(r.recommended_peer) AS rec_cnt
              FROM frend_union u JOIN recommendations r ON r.peer = u.peer2 AND r.recommended_peer != u.peer1
              GROUP BY peer1, recommended_peer) AS cnt_table;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_wich_peer_should_peer_be_evaluated();

/* 9) Determine the percentage of peers who:
   Started only block 1
   Started only block 2
   Started both
   Have not started any of them

   A peer is considered to have started a block if he has at least one check
   of any task from this block (according to the Checks table)
   Procedure parameters: name of block 1, for example SQL, name of block 2,
   for example A.
   Output format: percentage of those who started only the first block,
   percentage of those who started only the second block, percentage of those
   who started both blocks, percentage of those who did not started any of
   them */

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

SELECT * FROM fn_percent_by_blocks('C', 'CPP');

/* 10) Determine the percentage of peers who have ever successfully passed a
   check on their birthday

   Also determine the percentage of peers who have ever failed a check on
   their birthday.
   Output format: percentage  of peers who have ever successfully passed a
   check on their birthday, percentage of peers who have ever failed a check
   on their birthday */

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
            (SELECT (COUNT(DISTINCT peer) * 100 / NULLIF((SELECT * FROM cnt), 0))::INTEGER
             FROM birthday_checks WHERE state = 'success') as s CROSS JOIN
            (SELECT (COUNT(DISTINCT peer) * 100 / NULLIF((SELECT * FROM cnt), 0))::INTEGER
             FROM birthday_checks WHERE state = 'failure') as f;
    END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_birthday_checks_percentage();

/* 11) Determine all peers who did the given tasks 1 and 2, but did not do
   task 3

   Procedure parameters: names of tasks 1, 2 and 3.
   Output format: list of peers */

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
              (v.state IS NULL OR v.state = 'success')
        GROUP BY peer
        HAVING task1 = ANY(ARRAY_AGG(task))
            AND task2 = ANY(ARRAY_AGG(task))
            AND task3 != ALL(ARRAY_AGG(task));
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_check_peers_two_of_three_task_done('C5_s21_decimal', 'C3_s21_string+', 'C4_s21_math');

/* 12) Using recursive common table expression, output the number of preceding
   tasks for each task

   I. e. How many tasks have to be done, based on entry conditions, to get
   access to the current one.
    Output format: task name, number of preceding tasks */

CREATE OR REPLACE FUNCTION fn_tasks_parent()
    RETURNS TABLE(Task VARCHAR, PrevCount BIGINT)
AS $$
BEGIN
    RETURN QUERY
        WITH RECURSIVE t(title, parent_task) AS
            (SELECT title as task, parent_task as parent FROM tasks
            UNION ALL
            SELECT t1.title, t2.parent_task FROM t as t1, tasks as t2
            WHERE t1.parent_task = t2.title)
        SELECT title, COUNT(parent_task) FROM t GROUP BY title;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_tasks_parent();

/* 13) Find "lucky" days for checks. A day is considered "lucky" if it has at
   least N consecutive successful checks

   Parameters of the procedure: the N number of consecutive successful checks.
   The time of the check is the start time of the P2P step.
   Successful consecutive checks are the checks with no unsuccessful checks in
   between.
   The amount of XP for each of these checks must be at least 80% of the
   maximum.
   Output format: list of days */

CREATE OR REPLACE FUNCTION fn_lucky_days(n INTEGER)
    RETURNS TABLE(date DATE)
AS $$
BEGIN
    RETURN QUERY
    WITH checks_agg AS
        (SELECT checks.id, check_date, p1.check_time, (p2.state = 'success') AND (v.state IS NULL OR v.state = 'success')
                AND ((xp_amount * 100 / max_xp) >= 80) AS success
        FROM checks
            LEFT JOIN (SELECT check_id, check_time FROM p2p WHERE state = 'start') p1 ON p1.check_id = checks.id
            LEFT JOIN (SELECT check_id, state FROM p2p WHERE state != 'start') p2 ON p2.check_id = checks.id
            LEFT JOIN (SELECT check_id, state FROM verter WHERE state != 'start') v ON v.check_id = checks.id
            LEFT JOIN xp x ON checks.id = x.check_id LEFT JOIN tasks t ON checks.task = t.title),
         first_last_checks AS
        (SELECT * FROM
               (SELECT *, LAG(success) OVER (PARTITION BY check_date ORDER BY check_time) AS l1,
                          LAG(success, -1) OVER (PARTITION BY check_date ORDER BY check_time) AS l2 ,
                          ROW_NUMBER() OVER (PARTITION BY check_date, success ORDER BY check_time) AS r2
               FROM checks_agg) t1
           WHERE success = TRUE AND ((l1 IS NULL OR l1 = 'false') OR (l2 IS NULL OR l2 = 'false')))
    SELECT check_date FROM first_last_checks LEFT JOIN
        (SELECT id, LAG(r2) OVER (PARTITION BY check_date ORDER BY check_date, check_time) AS r1
         FROM first_last_checks WHERE (l1 = TRUE OR l2 = TRUE)) t1 ON t1.id = first_last_checks.id
    WHERE (l2 IS NULL OR l2 = 'false')
    GROUP BY check_date
    HAVING COALESCE(MAX(r2 - r1), 0) + 1 >= n
    ORDER BY check_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_lucky_days(3);

/* 14) Find the peer with the highest amount of XP
   Output format: peer's nickname, amount of XP */

CREATE OR REPLACE FUNCTION fn_get_peer_with_max_xp()
    RETURNS TABLE(peer VARCHAR, XP numeric)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.peer,
        SUM(t.xp) as XP
    FROM (
        SELECT f.peer, f.task, MAX(f.xp) as xp
        FROM fnc_get_peers_success_tasks_with_xp() f
        GROUP BY f.peer, f.task) as t
    GROUP BY t.peer
    ORDER BY XP DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_get_peer_with_max_xp();

/* 15) Determine the peers that came before the given time at least N times
   during the whole time

   Procedure parameters: time, N number of times .
   Output format: list of peers */

CREATE OR REPLACE FUNCTION fn_early_peers(t TIME, n INTEGER)
    RETURNS TABLE(peer VARCHAR)
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
    SELECT peer FROM
        (SELECT first_value(peer) OVER (PARTITION BY peer, date ORDER BY time) AS peer
         FROM time_tracking
         WHERE state = 1 AND time < t) agg
    GROUP BY peer HAVING COUNT(peer) >= n;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_early_peers('12:30:00', 1);
SELECT * FROM fn_early_peers('12:30:01', 1);
SELECT * FROM fn_early_peers('14:30:00', 2);

/* 16) Determine the peers who left the campus more than M times during the
   last N days

   Procedure parameters: N number of days , M number of times .
   Output format: list of peers */

CREATE OR REPLACE FUNCTION fn_get_going_out_peers(last_days_cnt INTEGER, going_out_cnt INTEGER)
    RETURNS TABLE(peer VARCHAR)
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
        SELECT peer FROM time_tracking
        WHERE state = 2 AND NOW()::DATE - date < last_days_cnt
        GROUP BY peer HAVING COUNT(peer) > going_out_cnt;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_get_going_out_peers(2, 1);

/* 17) Determine for each month the percentage of early entries

   For each month, count how many times people born in that month came to
   campus during the whole time (we'll call this the total number of entries).
   For each month, count the number of times people born in that month have
   come to campus before 12:00 in all time (we'll call this the number of
   early entries).
   For each month, count the percentage of early entries to campus relative to
   the total number of entries.
   Output format: month, percentage of early entries */

CREATE OR REPLACE FUNCTION fn_early_entries_per_birth_mohth()
    RETURNS TABLE(Month TEXT, EarlyEntries BIGINT)
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
        WITH agg AS
            (SELECT time, TO_CHAR(birthday, 'Month') AS month
            FROM time_tracking LEFT JOIN peers p ON p.nickname = time_tracking.peer
            WHERE state = 1),
             gs AS (SELECT TO_CHAR(generate_series('2018-01-31', '2018-12-31', INTERVAL '1 month'), 'Month') AS month)
        SELECT gs.month, coalesce(c2 * 100 / c1, 0) FROM gs LEFT JOIN
            (SELECT month, COUNT(month) AS c1 FROM agg GROUP BY month) a ON a.month = gs.month LEFT JOIN
            (SELECT month, COUNT(month) AS c2 FROM agg WHERE time < '12:00:00' GROUP BY month) b ON b.month = gs.month;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_early_entries_per_birth_mohth();