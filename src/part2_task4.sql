CREATE OR REPLACE FUNCTION fnc_trg_xp_max() RETURNS TRIGGER AS $xp$
    DECLARE
        p2pRows int;
        verterRows int;
        xpAmount int;
    BEGIN
        SELECT max_xp INTO xpAmount FROM tasks INNER JOIN checks c on tasks.title LIKE c.task WHERE c.id = NEW.check_id;
        IF (xpAmount > NEW.xp_amount) THEN
            RAISE EXCEPTION 'Xp amount (%) is greater than it should be', NEW.xp_amount;
        END IF;

        SELECT count(id) INTO p2pRows FROM p2p WHERE check_id = NEW.check_id AND state = 'success';
        IF (p2pRows = 0) THEN
            RAISE EXCEPTION 'P2P check is not success (check_id: %)', NEW.check_id;
        END IF;

        SELECT count(id) INTO verterRows FROM verter WHERE check_id = NEW.check_id AND state = 'success';
        IF (verterRows = 0) THEN
            RAISE EXCEPTION 'Verter check is not success (check_id: %)', NEW.check_id;
        END IF;

        RETURN NEW;
    END;
$xp$ LANGUAGE plpgsql;

CREATE TRIGGER trg_xp_max
    BEFORE INSERT OR UPDATE ON xp
    FOR EACH ROW EXECUTE PROCEDURE fnc_trg_xp_max();


-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------
--  check is not isset  -- should FAIL
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
INSERT INTO xp(check_id, xp_amount) VALUES (1, 200);

--  p2p check is not isset  -- should FAIL
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
INSERT INTO xp(check_id, xp_amount) VALUES (1, 200);

--  p2p check has only started  -- should FAIL
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
INSERT INTO xp(check_id, xp_amount) VALUES (1, 200);

--  Verter check has only started  -- should FAIL
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'success', '2023-03-30 22:35');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'start', '2023-03-30 22:45');
INSERT INTO xp(check_id, xp_amount) VALUES (1, 200);

--  p2p and Verter checks isset and has success but xp greater  -- should FAIL
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'success', '2023-03-30 22:35');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'start', '2023-03-30 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'success', '2023-03-30 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (1, 1000);

--  p2p and Verter checks isset and has success. xp is correct  -- should SUCCESS
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'success', '2023-03-30 22:35');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'start', '2023-03-30 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'success', '2023-03-30 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (1, 250);

--  clean up tables
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;