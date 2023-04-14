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


--TEST
INSERT INTO time_tracking VALUES(21, 'vindicat', '2023-04-15', '11:30:00', 1);
INSERT INTO time_tracking VALUES(22, 'vindicat', '2023-04-15', '12:30:00', 2);
INSERT INTO time_tracking VALUES(23, 'vindicat', '2023-04-14', '11:30:00', 1);
INSERT INTO time_tracking VALUES(24, 'vindicat', '2023-04-14', '12:30:00', 2);

SELECT * FROM fn_get_going_out_peers(2, 1);

DELETE FROM time_tracking WHERE id BETWEEN  21 AND 24;