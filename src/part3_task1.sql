-- PREPARE TEST DATA
TRUNCATE transferred_points RESTART IDENTITY CASCADE;
INSERT INTO peers(nickname, birthday) VALUES
    ('Aboba', '1999-01-02'),
    ('Amogus', '1999-01-02'),
    ('Sus', '1999-01-02');
INSERT INTO transferred_points(checking_peer, checked_peer, points_amount)
VALUES
    ('Aboba', 'Amogus', 5),
    ('Amogus', 'Sus', 3),
    ('Sus', 'Amogus', 5),
    ('Sus', 'Aboba', 2),
    ('Aboba', 'Sus', 2);

-- TASK FUNCTION
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

-- TEST
SELECT * FROM human_readable_transferredPoints();