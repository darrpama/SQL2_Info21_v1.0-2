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

-- TEST
INSERT INTO time_tracking VALUES(21, 'vindicat', '2023-02-15', '11:30:00', 1);
INSERT INTO time_tracking VALUES(22, 'vindicat', '2023-02-15', '12:30:00', 2);
INSERT INTO time_tracking VALUES(23, 'vindicat', '2023-02-14', '11:30:00', 1);
INSERT INTO time_tracking VALUES(24, 'vindicat', '2023-02-14', '12:30:00', 2);
INSERT INTO time_tracking VALUES(25, 'cindabru', '2023-02-14', '11:30:00', 1);
INSERT INTO time_tracking VALUES(26, 'cindabru', '2023-02-14', '12:30:00', 2);
INSERT INTO time_tracking VALUES(27, 'cindabru', '2023-02-15', '17:30:00', 1);
INSERT INTO time_tracking VALUES(28, 'cindabru', '2023-02-15', '18:30:00', 2);

SELECT * FROM fn_early_entries_per_birth_mohth();

DELETE FROM time_tracking WHERE id BETWEEN 21 AND 28;
