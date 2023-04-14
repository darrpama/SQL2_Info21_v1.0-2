CREATE OR REPLACE FUNCTION fnc_transfer_p2p_point()
RETURNS TRIGGER AS
$$
    BEGIN
        IF NEW.state = 'start' THEN
            WITH foo AS (
                SELECT DISTINCT NEW.checking_peer, checks.peer AS checked_peer FROM p2p
                JOIN checks ON p2p.check_id = new.check_id
                GROUP BY p2p.checking_peer, checked_peer
                )
            UPDATE transferred_points
            SET points_amount = transferred_points.points_amount + 1,
                id            = transferred_points.id
            FROM foo
            WHERE foo.checked_peer  = transferred_points.checked_peer AND
                  foo.checking_peer = transferred_points.checking_peer;
            RETURN NEW;
        ELSE
            RETURN NULL;
        END IF;
    END
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_transfer_p2p_point
    AFTER INSERT ON p2p
    FOR EACH ROW
EXECUTE FUNCTION fnc_transfer_p2p_point();

select * from transferred_points order by 1;


