CREATE OR REPLACE FUNCTION fnc_get_peers_success_tasks_with_xp()
    RETURNS TABLE (
        Peer varchar,
        Task varchar,
        XP bigint
    ) language plpgsql AS
$$
    BEGIN
        RETURN QUERY
        SELECT nickname, c.task, xp_amount FROM peers
            JOIN checks c on peers.nickname = c.peer
            JOIN xp x on c.id = x.check_id;
    END;
$$;

-- Prepare test data
--  clean up tables
TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- data 1
INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'success', '2023-03-30 22:35');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'start', '2023-03-30 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (1, 'success', '2023-03-30 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (1, 250);
-- data 2
INSERT INTO checks(peer, task, check_date) VALUES ('darrpama', 'C2_SimpleBashUtils', '2023-03-30 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (2, 'myregree', 'start', '2023-03-30 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (2, 'myregree', 'success', '2023-03-30 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (2, 'start', '2023-03-30 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (2, 'success', '2023-03-30 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (2, 250);
-- data 3
INSERT INTO checks(peer, task, check_date) VALUES ('maddiega', 'C2_SimpleBashUtils', '2023-03-29 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (3, 'darrpama', 'start', '2023-03-29 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (3, 'darrpama', 'success', '2023-03-29 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (3, 'start', '2023-03-29 22:45');
-- data 4
INSERT INTO checks(peer, task, check_date) VALUES ('darrpama', 'C2_SimpleBashUtils', '2023-03-31 22:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (2, 'maddiega', 'start', '2023-03-31 20:25');
INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (2, 'maddiega', 'success', '2023-03-31 20:35');
INSERT INTO verter(check_id, state, check_time) VALUES (2, 'start', '2023-03-30 22:45');
INSERT INTO verter(check_id, state, check_time) VALUES (2, 'success', '2023-03-30 22:55');
INSERT INTO xp(check_id, xp_amount) VALUES (2, 250);

SELECT * FROM fnc_get_peers_success_tasks_with_xp();