CREATE OR REPLACE FUNCTION fn_lucky_days(n INTEGER)
    RETURNS TABLE(date DATE)
AS $$
BEGIN
    RETURN QUERY
    WITH checks_agg AS
        (SELECT check_date, p1.check_time, (p2.state = 'success') AND (v.state IS NULL OR v.state = 'success')
                AND ((xp_amount * 100 / max_xp) >= 80) AS success
        FROM checks
            LEFT JOIN (SELECT check_id, check_time FROM p2p WHERE state = 'start') p1 ON p1.check_id = checks.id
            LEFT JOIN (SELECT check_id, state FROM p2p WHERE state != 'start') p2 ON p2.check_id = checks.id
            LEFT JOIN (SELECT check_id, state FROM verter WHERE state != 'start') v ON v.check_id = checks.id
            LEFT JOIN xp x ON checks.id = x.check_id LEFT JOIN tasks t ON checks.task = t.title)
    SELECT check_date FROM
        (SELECT *, LAG(r2) OVER (PARTITION BY check_date ORDER BY check_date, check_time) AS r1 FROM
            (SELECT * FROM
                (SELECT *, LAG(success) OVER (PARTITION BY check_date ORDER BY check_time) AS l1,
                           LAG(success, -1) OVER (PARTITION BY check_date ORDER BY check_time) AS l2 ,
                           ROW_NUMBER() OVER (PARTITION BY check_date, success ORDER BY check_time) AS r2
                FROM checks_agg) t1
            WHERE success = TRUE AND ((l1 IS NULL OR l1 = 'false') OR (l2 IS NULL OR l2 = 'false'))) t2) t3
    WHERE (l2 IS NULL OR l2 = 'false')
    GROUP BY check_date
    HAVING COALESCE(MAX(r2 - r1), 0) + 1 >= n
    ORDER BY check_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_lucky_days(3);