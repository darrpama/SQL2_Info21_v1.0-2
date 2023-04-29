--==========================================================---
----------------------- PART 2 task 1 -------------------------
--==========================================================---
-- Написать процедуру добавления P2P проверки
-- Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P проверки, время.
-- Если задан статус "начало", добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю).
-- Добавить запись в таблицу P2P.
-- Если задан статус "начало", в качестве проверки указать только что добавленную запись,
-- иначе указать проверку с незавершенным P2P этапом.
---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_add_p2p_check(
    new_checked_peer  text,
    new_checking_peer text,
    new_task_title    text,
    new_state         check_state,
    new_check_time    time
) AS $$
DECLARE
    new_check_id BIGINT := 0;
BEGIN
    IF new_state = 'start' THEN
        IF (SELECT count(*) FROM p2p JOIN checks c ON p2p.check_id = c.id
            WHERE p2p.checking_peer = new_checking_peer
              AND c.peer = new_checked_peer
              AND c.task = new_task_title) % 2 = 1
        THEN
            RAISE EXCEPTION 'The check cannot be added: peer has unfinished check';
        ELSE
            INSERT INTO checks (peer, task, check_date)
            VALUES (new_checked_peer, new_task_title, now())
            RETURNING id INTO new_check_id;

            INSERT INTO p2p (check_id, checking_peer, state, check_time)
            VALUES (new_check_id, new_checking_peer, new_state, new_check_time);
        END IF;
    ELSE
        IF (SELECT state FROM p2p JOIN checks c ON p2p.check_id = c.id
            WHERE p2p.checking_peer = new_checking_peer
              AND c.peer = new_checked_peer
              AND c.task = new_task_title
            ORDER BY p2p.id DESC LIMIT 1) != 'start'
        THEN
            RAISE EXCEPTION 'The check cannot be added: peer dont have started check';
        ELSE
            IF (SELECT state FROM p2p JOIN checks c ON p2p.check_id = c.id
                WHERE p2p.checking_peer = new_checking_peer
                    AND c.peer = new_checked_peer
                    AND c.task = new_task_title
                ORDER BY p2p.id DESC LIMIT 1) != 'start'
            THEN
                RAISE EXCEPTION 'The check cannot be added: peer dont have started check';
            ELSE
                new_check_id = (
                    SELECT c.id FROM p2p
                        INNER JOIN checks c ON c.id = p2p.check_id
                    WHERE c.peer = new_checked_peer
                        AND p2p.checking_peer = new_checking_peer
                        AND task = new_task_title
                    ORDER BY c.id DESC LIMIT 1
                );
                INSERT INTO p2p (check_id, checking_peer, state, check_time)
                VALUES (new_check_id, new_checking_peer, new_state, new_check_time);
            END IF;
        END IF;
    END IF;
END
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------
TRUNCATE checks, p2p RESTART IDENTITY CASCADE;
-- Сначала таблицы, в которые будут добавляться записи очищаются.
SELECT * FROM p2p;
SELECT * FROM checks;
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '15:30:01');
SELECT * FROM p2p;
SELECT * FROM checks;
-- Вызов каждой процедуры повторно вызовет exception
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '15:30:01');
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'success'::check_state, '15:30:01');
SELECT * FROM p2p;
SELECT * FROM checks;

TRUNCATE checks RESTART IDENTITY CASCADE;
CALL import_from_csv ('checks', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-2/src/csv/03-init_checks.csv', ',');
SELECT setval('checks_id_seq', (SELECT MAX(id) FROM checks)+1);

TRUNCATE p2p RESTART IDENTITY CASCADE;
CALL import_from_csv ('p2p', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-2/src/csv/04-init_p2p.csv', ',');
SELECT setval('p2p_id_seq', (SELECT MAX(id) FROM p2p)+1);

TRUNCATE verter RESTART IDENTITY CASCADE;
CALL import_from_csv ('verter', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-2/src/csv/05-init_verter.csv', ',');
SELECT setval('verter_id_seq', (SELECT MAX(id) FROM verter)+1);


--==========================================================---
----------------------- PART 2 task 2 -------------------------
--==========================================================---
-- Написать процедуру добавления проверки Verter'ом
-- Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время.
-- Добавить запись в таблицу Verter (в качестве проверки указать проверку соответствующего
-- задания с самым поздним (по времени) успешным P2P этапом)
---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_add_verter_check(
    new_checked_peer text,
    new_task_title   text,
    new_state        check_state,
    new_check_time   time
) AS $$
    DECLARE
        checkId bigint := (
            SELECT check_id
            FROM p2p
                JOIN checks ON p2p.check_id = checks.id
                    AND checks.task = new_task_title
                    AND checks.peer = new_checked_peer
            WHERE state = 'success'
            ORDER BY check_date, check_time DESC LIMIT 1);
        verter_started   check_state := (SELECT state FROM verter WHERE check_id = checkId AND state = 'start');
        verter_failed    check_state := (SELECT state FROM verter WHERE check_id = checkId AND state = 'failure');
        verter_finished  check_state := (SELECT state FROM verter WHERE check_id = checkId AND state != 'start');
    BEGIN
        IF (new_state = 'start' AND checkId IS NULL)            THEN RAISE EXCEPTION 'P2P must be success'; END IF;
        IF (new_state = 'start' AND verter_started IS NOT NULL
        AND verter_failed IS NULL)                              THEN RAISE EXCEPTION 'Verter check has been already started'; END IF;
        IF (new_state != 'start' AND verter_started IS NULL)    THEN RAISE EXCEPTION 'Verter check must be started'; END IF;
        IF (verter_finished IS NOT NULL
        AND verter_failed IS NULL)                              THEN RAISE EXCEPTION 'Verter check has been already done'; END IF;

        INSERT INTO verter (check_id, state, check_time)
        VALUES (checkId, new_state, new_check_time);
    END
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------
--
-- SELECT * FROM p2p JOIN checks ON p2p.check_id = checks.id
--     AND checks.task = 'C2_SimpleBashUtils'
--     AND checks.peer = 'darrpama'
-- ORDER BY check_date, check_time LIMIT 1;
--
-- SELECT * FROM verter JOIN checks c ON verter.check_id = c.id
-- WHERE c.peer = 'darrpama'
--     AND c.task = 'C2_SimpleBashUtils'
--     AND verter.state = 'start';

TRUNCATE checks, p2p, verter RESTART IDENTITY CASCADE;
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '15:30:02');
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'failure'::check_state, '15:30:01');
CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'start', '22:50:00');

SELECT * FROM p2p;
SELECT * FROM checks;
SELECT * FROM verter;

TRUNCATE checks, p2p, verter RESTART IDENTITY CASCADE;
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '15:30:01');
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'success'::check_state, '15:30:01');
CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'start', '16:50:00');
CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'failure', '16:50:01');

CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '16:55:01');
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'success'::check_state, '16:55:02');
CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'start', '22:50:00');
CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'success', '22:50:01');

SELECT * FROM p2p;
SELECT * FROM checks;
SELECT * FROM verter;

TRUNCATE checks, p2p, verter RESTART IDENTITY CASCADE;
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'start'::check_state, '15:30:01');
CALL pr_add_p2p_check('darrpama', 'myregree', 'C2_SimpleBashUtils', 'success'::check_state, '15:30:01');
CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'start', '22:50:00');
CALL pr_add_verter_check('darrpama', 'C2_SimpleBashUtils', 'success', '22:50:01');

SELECT * FROM p2p;
SELECT * FROM checks;
SELECT * FROM verter;
TRUNCATE checks RESTART IDENTITY CASCADE;
CALL import_from_csv ('checks', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-2/src/csv/03-init_checks.csv', ',');
SELECT setval('checks_id_seq', (SELECT MAX(id) FROM checks)+1);

TRUNCATE p2p RESTART IDENTITY CASCADE;
CALL import_from_csv ('p2p', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-2/src/csv/04-init_p2p.csv', ',');
SELECT setval('p2p_id_seq', (SELECT MAX(id) FROM p2p)+1);

TRUNCATE verter RESTART IDENTITY CASCADE;
CALL import_from_csv ('verter', '/Users/darrpama/projects/sql/SQL2_Info21_v1.0-2/src/csv/05-init_verter.csv', ',');
SELECT setval('verter_id_seq', (SELECT MAX(id) FROM verter)+1);


--==========================================================---
----------------------- PART 2 task 3 -------------------------
--==========================================================---
-- Написать триггер: после добавления записи со статутом "начало" в таблицу P2P,
-- изменить соответствующую запись в таблице TransferredPoints
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION fnc_transfer_p2p_point() RETURNS TRIGGER AS
$$
    DECLARE
        checkedPeer text := (
            SELECT checks.peer
            FROM checks
                JOIN p2p ON p2p.check_id = checks.id AND p2p.check_id = NEW.check_id
            WHERE checking_peer = NEW.checking_peer LIMIT 1
        );
        transferRecord BOOL := (
            SELECT EXISTS(
                SELECT id FROM transferred_points
                WHERE checking_peer = NEW.checking_peer
                    AND checked_peer = checkedPeer
            )::BOOL
        );
    BEGIN
        IF NEW.state = 'start' THEN
            IF (transferRecord IS FALSE) THEN
                INSERT INTO transferred_points (checking_peer, checked_peer, points_amount)
                VALUES (NEW.checking_peer, checkedPeer, 1);
            ELSE
                UPDATE transferred_points tp SET points_amount = tp.points_amount + 1
                WHERE tp.checked_peer = checkedPeer
                  AND tp.checking_peer = NEW.checking_peer;
            END IF;
            RETURN NEW;
        ELSE
            RETURN NULL;
        END IF;
    END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transfer_p2p_point AFTER INSERT ON p2p FOR EACH ROW
EXECUTE FUNCTION fnc_transfer_p2p_point();

-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------
-- TRUNCATE checks, p2p, verter, xp, transferred_points RESTART IDENTITY CASCADE;
-- SELECT * FROM checks;
-- SELECT * FROM p2p;
-- SELECT * FROM transferred_points;
-- CALL pr_add_p2p_check('darrpama', 'myregree', 'C7_SmartCalc_v1.0', 'start'::check_state, '15:30:01');
-- SELECT * FROM transferred_points;
-- CALL pr_add_p2p_check('darrpama', 'myregree', 'C7_SmartCalc_v1.0', 'success'::check_state, '15:30:01');
-- CALL pr_add_p2p_check('darrpama', 'myregree', 'C7_SmartCalc_v1.0', 'start'::check_state, '15:30:01');
-- SELECT * FROM transferred_points;


--==========================================================---
----------------------- PART 2 task 4 -------------------------
--==========================================================---
-- Написать триггер: перед добавлением записи в таблицу XP,
-- проверить корректность добавляемой записи
---------------------------------------------------------------
CREATE OR REPLACE FUNCTION fnc_trg_xp_max() RETURNS TRIGGER AS $xp$
    DECLARE
        maxXp         INT  := (SELECT max_xp FROM tasks INNER JOIN checks c on tasks.title LIKE c.task WHERE c.id = NEW.check_id);
        p2pCheck      BOOL := (SELECT EXISTS(SELECT id FROM p2p WHERE check_id = NEW.check_id AND state = 'success')::BOOL);
        verterIsset   BOOL := (SELECT EXISTS(SELECT id FROM verter WHERE check_id = NEW.check_id AND state = 'start')::BOOL);
        verterSuccess BOOL := (SELECT EXISTS(SELECT id FROM verter WHERE check_id = NEW.check_id AND state = 'success')::BOOL);
    BEGIN
        IF (NEW.xp_amount > maxXp)
            THEN RAISE EXCEPTION 'Cannot add xp - xp amount (%) is greater than it should be', NEW.xp_amount; END IF;

        IF (p2pCheck IS FALSE)
            THEN RAISE EXCEPTION 'Cannot add xp - P2P check is not success (check_id: %)', NEW.check_id; END IF;

        IF (verterIsset IS TRUE AND verterSuccess IS FALSE)
            THEN RAISE EXCEPTION 'Cannot add xp - Verter check is not success (check_id: %)', NEW.check_id; END IF;

        RETURN NEW;
    END;
$xp$ LANGUAGE plpgsql;

CREATE TRIGGER trg_xp_max
    BEFORE INSERT OR UPDATE ON xp
    FOR EACH ROW EXECUTE PROCEDURE fnc_trg_xp_max();

-------------------------------------------------------------------------------------------
-- TEST CASES
-------------------------------------------------------------------------------------------
-- --  check is not isset  -- should FAIL
-- TRUNCATE checks, p2p, verter, xp, transferred_points RESTART IDENTITY CASCADE;
-- INSERT INTO xp(check_id, xp_amount) VALUES (1, 200);
-- --  p2p check is not isset  -- should FAIL
-- TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
-- INSERT INTO xp(check_id, xp_amount) VALUES (1, 200);
-- --  p2p check has only started  -- should FAIL
-- TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
-- INSERT INTO xp(check_id, xp_amount) VALUES (1, 200);
-- --  Verter check has only started  -- should FAIL
-- TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'success', '2023-03-30 22:35');
-- INSERT INTO verter(check_id, state, check_time) VALUES (1, 'start', '2023-03-30 22:45');
-- INSERT INTO xp(check_id, xp_amount) VALUES (1, 200);
-- --  p2p and Verter checks isset and has success but xp greater  -- should FAIL
-- TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'success', '2023-03-30 22:35');
-- INSERT INTO verter(check_id, state, check_time) VALUES (1, 'start', '2023-03-30 22:45');
-- INSERT INTO verter(check_id, state, check_time) VALUES (1, 'success', '2023-03-30 22:55');
-- INSERT INTO xp(check_id, xp_amount) VALUES (1, 1000);
-- --  p2p and Verter checks isset and has success. xp is correct  -- should SUCCESS
-- TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'success', '2023-03-30 22:35');
-- INSERT INTO verter(check_id, state, check_time) VALUES (1, 'start', '2023-03-30 22:45');
-- INSERT INTO verter(check_id, state, check_time) VALUES (1, 'success', '2023-03-30 22:55');
-- INSERT INTO xp(check_id, xp_amount) VALUES (1, 250);
-- --  p2p checks isset and has success. Verter not isset. Xp is correct  -- should SUCCESS
-- TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;
-- INSERT INTO checks(peer, task, check_date) VALUES ('myregree', 'C2_SimpleBashUtils', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'start', '2023-03-30 22:25');
-- INSERT INTO p2p(check_id, checking_peer, state, check_time) VALUES (1, 'darrpama', 'success', '2023-03-30 22:35');
-- INSERT INTO xp(check_id, xp_amount) VALUES (1, 250);
-- --  clean up tables
-- TRUNCATE checks, p2p, verter, xp RESTART IDENTITY CASCADE;