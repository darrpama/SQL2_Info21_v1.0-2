-- TASK FUNCTION
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


-- PREPARE TEST DATA
TRUNCATE time_tracking RESTART IDENTITY CASCADE;
INSERT INTO peers (nickname, birthday)
    VALUES ('dedelmir', '1999-02-08')
INSERT INTO time_tracking (peer, date, time, state)
    VALUES ('dedelmir', '2023-04-08', '8:33', 1),
           ('dedelmir', '2023-04-08', '18:33', 2),
           ('myregree', '2023-04-08', '13:33', 1),
           ('myregree', '2023-04-08', '15:20', 2),
           ('myregree', '2023-04-08', '15:35', 1),
           ('myregree', '2023-04-08', '18:11', 2),
           ('darrpama', '2023-04-08', '13:11', 1),
           ('darrpama', '2023-04-08', '18:11', 2);

-- TEST
SELECT * FROM fn_get_peers_without_break_during_the_day('2023-04-08');

