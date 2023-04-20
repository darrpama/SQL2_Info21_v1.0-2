--==========================================================---
--------------------- CREATE PROCEDURES -----------------------
--==========================================================---
-- Написать процедуру добавления P2P проверки
-- Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P проверки, время.
-- Если задан статус "начало", добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю).
-- Добавить запись в таблицу P2P.
-- Если задан статус "начало", в качестве проверки указать только что добавленную запись,
-- иначе указать проверку с незавершенным P2P этапом.
---------------------------------------------------------------


CREATE OR REPLACE PROCEDURE pr_add_p2p_check(new_checked_peer text, new_checking_peer text, new_task_title text, new_state check_state, new_check_time time)
AS $$
DECLARE
    new_check_id BIGINT := 0;
BEGIN
    IF new_state = 'start' THEN
        IF ((SELECT count(*) FROM p2p
             JOIN checks ON p2p.check_id = checks.id
             WHERE p2p.checking_peer = new_checking_peer
               AND checks.peer = new_checked_peer
               AND checks.task = new_task_title
               ) % 2 = 1)
        THEN
            RAISE EXCEPTION 'Last check with same peer must be done';
        ELSE
            INSERT INTO checks (peer, task, check_date)
            VALUES (new_checked_peer, new_task_title, now());
            new_check_id = (SELECT max(id) FROM checks);

            INSERT INTO p2p (check_id, checking_peer, state, check_time)
            VALUES (new_check_id, new_checking_peer, new_state, new_check_time);
        END IF;
    ELSE
        new_check_id = (SELECT checks.id FROM p2p
                        INNER JOIN checks ON checks.id = p2p.check_id
                        WHERE checks.peer = new_checked_peer
                          AND p2p.checking_peer = new_checking_peer
                          AND task = new_task_title
                        ORDER BY checks.id DESC LIMIT 1);
        INSERT INTO p2p (check_id, checking_peer, state, check_time)
        VALUES (new_check_id, new_checking_peer, new_state, new_check_time);
    END IF;
END
$$ LANGUAGE plpgsql;

-- TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;


-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------

SELECT * FROM p2p WHERE checking_peer = 'myregree';
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '15:30:01');
SELECT * FROM p2p WHERE checking_peer = 'myregree';
-- Вызов команды повторно вызовет exception
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '15:30:01');
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'success'::check_state, '15:30:01');
DELETE FROM p2p WHERE checking_peer = 'myregree' AND state = 'start';


--==========================================================---
-- Написать процедуру добавления проверки Verter'ом
-- Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время.
-- Добавить запись в таблицу Verter (в качестве проверки указать проверку соответствующего
-- задания с самым поздним (по времени) успешным P2P этапом)
---------------------------------------------------------------


CREATE OR REPLACE PROCEDURE pr_add_verter_check(new_checked_peer text, new_task_title text, new_state check_state, new_check_time time)
AS
$$
DECLARE
--     check_id BIGINT := 0;
    checkId bigint := (SELECT check_id
                         FROM p2p JOIN checks ON p2p.check_id = checks.id
                         AND checks.task = new_task_title
                         AND checks.peer = new_checked_peer
                        WHERE state = 'success'
                        ORDER BY check_date, check_time LIMIT 1);
    checkStartVerter  check_state := (SELECT state FROM verter WHERE check_id = checkId AND state = 'start');
    checkFinishVerter  check_state := (SELECT state FROM verter WHERE check_id = checkId AND state != 'start');

    BEGIN
    IF (new_state = 'start') THEN
        IF (checkId IS NULL) THEN
            RAISE EXCEPTION 'P2P must be success';
        ELSIF (checkStartVerter IS NOT NULL) THEN
            RAISE EXCEPTION 'Verter check has been already started';
        END IF;
    ELSIF (checkStartVerter IS NULL)
        THEN
            RAISE EXCEPTION 'Verter check must be started';
    ELSIF (checkFinishVerter IS NOT NULL)
        THEN
            RAISE EXCEPTION 'Verter check has been already done';
    END IF;
    INSERT INTO verter (check_id, state, check_time)
    VALUES (checkId, new_state, new_check_time);
END
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------
SELECT *
FROM p2p JOIN checks ON p2p.check_id = checks.id
AND checks.task = 'C2_SimpleBashUtils'
AND checks.peer = 'darrpama'
ORDER BY check_date, check_time LIMIT 1;

SELECT * FROM verter
             JOIN checks c ON verter.check_id = c.id
             WHERE c.peer = 'darrpama'
               AND c.task = 'C2_SimpleBashUtils'
               AND verter.state = 'start';

TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;

CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '15:30:01');
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'success'::check_state, '15:30:01');
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'failure'::check_state, '15:30:01');


CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'start', '22:50:00');
CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'success', '22:50:01');


--==========================================================---
--------------------- CREATE TRIGGERS -------------------------
--==========================================================---
-- Написать триггер: после добавления записи со статутом "начало"
-- в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints
---------------------------------------------------------------


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


-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------


SELECT * FROM transferred_points WHERE checked_peer = '' ORDER BY 1;
CALL pr_add_p2p_check('darrpama', 'myregree', 'C7_SmartCalc_v1.0', 'start'::check_state, '15:30:01');
SELECT * FROM transferred_points WHERE checked_peer = '' ORDER BY 1;


--==========================================================---
-- Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи
---------------------------------------------------------------


CREATE OR REPLACE FUNCTION fnc_trg_xp_max() RETURNS TRIGGER AS $xp$
DECLARE
    p2pRows    INT;
    xpAmount   INT;
    verterRows INT;
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