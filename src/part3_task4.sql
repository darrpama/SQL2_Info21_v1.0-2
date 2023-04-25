-- TASK FUNCTION
CREATE OR REPLACE FUNCTION fn_count_peer_points_changes_by_transferredPoints()
    RETURNS TABLE (
        Peer varchar,
        PointsChange numeric
    )
    language plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        checking.peer,
        (income - outcome)
    FROM (
        SELECT
            tp1.checking_peer as peer,
            sum(tp1.points_amount) as income
        FROM transferred_points tp1
        GROUP BY tp1.checking_peer
    ) AS checking
        JOIN (
            SELECT
                tp1.checked_peer as peer,
                sum(tp1.points_amount) as outcome
            FROM transferred_points tp1
            GROUP BY tp1.checked_peer
        ) AS checked ON checking.peer = checked.peer;
END; $$;

-- PREPARE TEST DATA
TRUNCATE transferred_points, peers RESTART IDENTITY CASCADE;
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

-- TEST
SELECT * FROM fn_count_peer_points_changes_by_transferredPoints();
-- ASSERT
--  Amogus -7
--  Sus     2
--  Aboba   5






