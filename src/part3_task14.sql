CREATE OR REPLACE FUNCTION fn_get_peer_with_max_xp()
    RETURNS TABLE(peer VARCHAR, XP numeric)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.peer,
        SUM(t.xp) as XP
    FROM fnc_get_peers_success_tasks_with_xp() as t
    GROUP BY t.peer
    ORDER BY XP DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_get_peer_with_max_xp();