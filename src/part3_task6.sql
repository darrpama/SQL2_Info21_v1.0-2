-- FUNCTION TEMPLATE
-- CREATE OR REPLACE FUNCTION fn_count_peer_points_changes_by_human_readable_func ()
--     RETURNS TABLE (
--         Peer varchar,
--         PointsChange numeric
--     )
--     language plpgsql
-- AS $$
-- BEGIN
--     RETURN QUERY
--     SELECT peerlist.peer, sum(pointsamount)
--     FROM (
--         (SELECT peer1 as peer, pointsamount FROM human_readable_transferredPoints() t1)
--         UNION ALL
--         (SELECT peer2 as peer, (pointsamount * -1) FROM human_readable_transferredPoints() t1)
--     ) as peerlist
--     GROUP BY peerlist.peer;
-- END; $$;

-- TEST
SELECT check_date, count(task), task FROM checks
GROUP BY check_date, task
ORDER BY check_date;
-- ASSERT
--   Amogus   -7
--   myregree  0
--   Sus       0
--   Aboba     7
