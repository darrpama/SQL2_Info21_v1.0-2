-- CREATE OR REPLACE PROCEDURE proc_wich_peer_should_peer_be_evaluated(IN r REFCURSOR)
-- AS $$
-- BEGIN
--     OPEN r FOR
--         WITH cnt_table AS (SELECT peer1 AS presenter, recommended_peer, COUNT(recommended_peer) AS rec_cnt
--                            FROM ((SELECT peer1, peer2 FROM friends UNION
--                                   SELECT peer2 AS peer1, peer1 AS peer2 FROM friends) AS u
--                                   JOIN recommendations r ON r.peer = u.peer2 AND r.recommended_peer != u.peer1)
--                                   GROUP BY peer1, recommended_peer)
--         SELECT DISTINCT presenter, FIRST_VALUE(recommended_peer) OVER (PARTITION BY presenter ORDER BY rec_cnt DESC)
--         FROM cnt_table;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- BEGIN;
-- CALL proc_wich_peer_should_peer_be_evaluated('ref');
-- FETCH ALL IN "ref";
-- END;

CREATE OR REPLACE FUNCTION fn_wich_peer_should_peer_be_evaluated()
    RETURNS TABLE (peer VARCHAR, recommended_peer VARCHAR)
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

-- TEST
INSERT INTO recommendations VALUES (8, 'woodensa', 'chastity');
SELECT * FROM fn_wich_peer_should_peer_be_evaluated();
-- darrpama -> chastity x2
DELETE FROM recommendations WHERE id = 8;