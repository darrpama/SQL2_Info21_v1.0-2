CREATE OR REPLACE FUNCTION fnc_transfer_p2p_point()
RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.state = 'start' THEN
    WITH foo AS (
        SELECT checking_peer, peer FROM p2p
        JOIN checks ON p2p.check_id = checks.id
        WHERE state = 'start' AND checks.id = 4
        )
    UPDATE transferred_points
    SET points_amount = transferred_points.points_amount + 1
    FROM foo
    WHERE foo.peer = transferred_points.checked_peer AND
          NEW.checking_peer = transferred_points.checking_peer;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trg_transfer_p2p_point
    AFTER INSERT ON p2p
    FOR EACH ROW
EXECUTE FUNCTION fnc_transfer_p2p_point();


INSERT INTO checks VALUES ('', );