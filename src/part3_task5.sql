-- TASK FUNCTION
CREATE OR REPLACE FUNCTION fn_count_peer_points_changes_by_human_readable_func ()
    RETURNS TABLE (
        Peer varchar,
        PointsChange numeric
    )
    language plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT peerlist.peer, sum(pointsamount)
    FROM (
        (SELECT peer1 as peer, pointsamount FROM human_readable_transferredPoints() t1)
        UNION ALL
        (SELECT peer2 as peer, (pointsamount * -1) FROM human_readable_transferredPoints() t1)
    ) as peerlist
    GROUP BY peerlist.peer;
END; $$;

-- PREPARE TEST DATA
TRUNCATE transferred_points, peers RESTART IDENTITY CASCADE;
INSERT INTO peers(nickname, birthday) VALUES
    ('Aboba', '1999-01-02'),
    ('Amogus', '1999-01-02'),
    ('Sus', '1999-01-02'),
    ('myregree', '1999-01-02');
INSERT INTO transferred_points(checking_peer, checked_peer, points_amount)
VALUES
    ('Aboba', 'Amogus', 5),
    ('Amogus', 'Sus', 3),
    ('Sus', 'Amogus', 5),
    ('Sus', 'Aboba', 2),
    ('Aboba', 'Sus', 2),
    ('myregree', 'Sus', 2),
    ('myregree', 'Aboba', 1),
    ('Aboba', 'myregree', 3);

-- TEST
SELECT * FROM fn_count_peer_points_changes_by_human_readable_func();
-- ASSERT
--   Amogus   -7
--   myregree  0
--   Sus       0
--   Aboba     7