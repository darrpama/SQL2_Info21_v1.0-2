CREATE OR REPLACE FUNCTION fnc_transfer_p2p_point()
RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.state = 'start' THEN
    UPDATE transferred_points
    SET points_amount = transferred_points.points_amount + 1,
    FROM ...
    WHERE ...
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT DISTINCT checking_peer, peer FROM p2p JOIN checks ON p2p.check_id = 34;


CREATE TRIGGER  trg_transfer_p2p_point
    AFTER INSERT ON p2p
    FOR EACH ROW
EXECUTE FUNCTION fnc_transfer_p2p_point();