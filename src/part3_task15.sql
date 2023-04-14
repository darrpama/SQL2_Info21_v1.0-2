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

SELECT * FROM fn_early_peers('12:30:00', 2);