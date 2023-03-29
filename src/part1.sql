--==========================================================---
------------------------ CREATE TABLES ------------------------
--==========================================================---

-- PEERS table
---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS peers (
    nickname VARCHAR PRIMARY KEY,
    birthday DATE NOT NULL
);

-- TASKS table
---------------------------------------------------------------
-- Чтобы получить доступ к заданию, нужно выполнить задание, являющееся его условием входа.
-- Для упрощения будем считать, что у каждого задания всего одно условие входа.
-- В таблице должно быть одно задание, у которого нет условия входа (т.е. поле ParentTask равно null).
CREATE TABLE IF NOT EXISTS tasks (
    title       VARCHAR PRIMARY KEY,
    parent_task VARCHAR CHECK ( parent_task NOT LIKE title ),
    max_xp      BIGINT NOT NULL CHECK ( max_xp > 0 ),
    CONSTRAINT fk_tasks_tasks FOREIGN KEY (parent_task) REFERENCES tasks(title)
);


-- CHECKS table
---------------------------------------------------------------
-- Проверка обязательно включает в себя один этап P2P
--     и, возможно, этап Verter.

-- Пир ту пир и автотесты, относящиеся к одной проверке,
--     всегда происходят в один день.

-- Проверка считается успешной,
--     если соответствующий P2P этап успешен,
--     а этап Verter успешен, либо отсутствует.

-- Проверка считается неуспешной, хоть один из этапов неуспешен.
--     Проверки, в которых ещё не завершился этап P2P,
--     или этап P2P успешен, но ещё не завершился этап Verter,
--     не относятся ни к успешным, ни к неуспешным.
CREATE TABLE IF NOT EXISTS checks (
    id          BIGSERIAL PRIMARY KEY,
    peer        VARCHAR NOT NULL,
    task        VARCHAR NOT NULL,
    check_date  DATE NOT NULL,
    CONSTRAINT fk_checks_peers FOREIGN KEY (peer) REFERENCES peers(nickname),
    CONSTRAINT fk_checks_tasks FOREIGN KEY (task) REFERENCES tasks(title)
);


-- ENUMS
---------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'check_state') THEN
        CREATE TYPE check_state AS ENUM ('start', 'success', 'failure');
    END IF;
    --more types here...
END$$;


-- P2P table
---------------------------------------------------------------
-- Каждая P2P проверка состоит из 2-х записей в таблице: первая имеет статус начало, вторая - успех или неуспех.
-- В таблице не может быть больше одной незавершенной P2P проверки, относящейся к конкретному заданию, пиру и проверяющему.
-- Каждая P2P проверка (т.е. обе записи, из которых она состоит) ссылается на проверку в таблице Checks, к которой она относится.
CREATE TABLE IF NOT EXISTS p2p (
    id              BIGSERIAL PRIMARY KEY,
    check_id        BIGINT NOT NULL,
    checking_peer   VARCHAR NOT NULL,
    state           check_state NOT NULL,
    check_time      TIME NOT NULL,
    CONSTRAINT fk_p2p_checks FOREIGN KEY (check_id) REFERENCES checks(id),
    CONSTRAINT fk_p2p_peers FOREIGN KEY (checking_peer) REFERENCES peers(nickname)
);


-- VERTER table
---------------------------------------------------------------
-- Каждая проверка Verter'ом состоит из 2-х записей в таблице: первая имеет статус начало, вторая - успех или неуспех.
-- Каждая проверка Verter'ом (т.е. обе записи, из которых она состоит) ссылается на проверку в таблице Checks, к которой она относится.
-- Проверка Verter'ом может ссылаться только на те проверки в таблице Checks, которые уже включают в себя успешную P2P проверку.
CREATE TABLE IF NOT EXISTS verter (
    id          BIGSERIAL PRIMARY KEY,
    check_id    BIGINT NOT NULL,
    state       check_state NOT NULL,
    check_time  TIME NOT NULL,
    CONSTRAINT fk_verter_checks FOREIGN KEY (check_id) REFERENCES checks(id)
);


-- TRANSFERRED_POINTS table
---------------------------------------------------------------
-- При каждой P2P проверке проверяемый пир передаёт 1 пир поинт проверяющему.
-- Эта таблица содержит
--      все пары проверяемый-проверяющий
--      и кол-во переданных пир поинтов,
--      другими словами,
--          количество P2P проверок указанного проверяемого пира, данным проверяющим.
CREATE TABLE IF NOT EXISTS transferred_points (
    id              BIGSERIAL PRIMARY KEY,
    checking_peer   VARCHAR NOT NULL CHECK ( checking_peer NOT LIKE checked_peer),
    checked_peer    VARCHAR NOT NULL CHECK ( checked_peer NOT LIKE checking_peer),
    points_amount   BIGINT NOT NULL CHECK ( points_amount > 0 ),
    CONSTRAINT fk_transferred_points_peers_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers(nickname),
    CONSTRAINT fk_transferred_points_peers_checked_peer FOREIGN KEY (checked_peer) REFERENCES peers(nickname)
);


-- FRIENDS table
---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS friends (
    id      BIGSERIAL PRIMARY KEY,
    peer1   VARCHAR NOT NULL CHECK ( peer1 NOT LIKE  peer2),
    peer2   VARCHAR NOT NULL CHECK ( peer2 NOT LIKE peer1 ),
    CONSTRAINT fk_friends_peers_peer1 FOREIGN KEY (peer1) REFERENCES peers(nickname),
    CONSTRAINT fk_friends_peers_peer2 FOREIGN KEY (peer2) REFERENCES peers(nickname)
);

-- RECOMMENDATIONS table
---------------------------------------------------------------
-- Каждому может понравиться, как проходила P2P проверка у того или иного пира.
-- Пир, указанный в поле Peer, рекомендует проходить P2P проверку у пира из поля RecommendedPeer.
-- Каждый пир может рекомендовать как ни одного, так и сразу несколько проверяющих.
CREATE TABLE IF NOT EXISTS recommendations
(
    id                  BIGSERIAL PRIMARY KEY,
    peer                VARCHAR NOT NULL CHECK ( peer NOT LIKE  recommended_peer),
    recommended_peer    VARCHAR NOT NULL CHECK ( recommended_peer NOT LIKE peer ),
    CONSTRAINT fk_recommendations_peers_peer FOREIGN KEY (peer) REFERENCES peers(nickname),
    CONSTRAINT fk_recommendations_peers_recommended_peer FOREIGN KEY (recommended_peer) REFERENCES peers(nickname)
);


-- XP table
---------------------------------------------------------------
-- За каждую успешную проверку пир, выполнивший задание, получает какое-то количество XP, отображаемое в этой таблице.
-- Количество XP не может превышать максимальное доступное для проверяемой задачи.
-- Первое поле этой таблицы может ссылаться только на успешные проверки.
CREATE TABLE IF NOT EXISTS xp
(
    id          BIGSERIAL PRIMARY KEY,
    check_id    BIGINT NOT NULL,
    xp_amount   BIGINT NOT NULL CHECK ( xp_amount > 0 ),
    CONSTRAINT fk_xp_check FOREIGN KEY (check_id) REFERENCES checks(id)
);


-- TIME_TRACKING table
---------------------------------------------------------------
-- Данная таблица содержит информация о посещениях пирами кампуса.
-- Когда пир входит в кампус, в таблицу добавляется запись с состоянием 1,
-- когда покидает - с состоянием 2.
-- В заданиях, относящихся к этой таблице, под действием "выходить" подразумеваются все покидания кампуса за день, кроме последнего.
-- В течение одного дня должно быть одинаковое количество записей с состоянием 1 и состоянием 2 для каждого пира.
CREATE TABLE IF NOT EXISTS time_tracking
(
    id      BIGSERIAL PRIMARY KEY,
    peer    VARCHAR NOT NULL,
    "date"  DATE NOT NULL,
    "time"  TIME NOT NULL,
    state   SMALLINT NOT NULL CHECK(state in (1,2)),
    CONSTRAINT fk_time_tracking_peers FOREIGN KEY (peer) REFERENCES peers(nickname)
);

---------------------------------------------------------------------------------------------
-- IMPORT FROM CSV
---------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE import_from_csv(
    table_name varchar,
    global_path varchar,
    delimiter varchar
) AS $$
    BEGIN
        EXECUTE format(
            'copy %s FROM %L WITH DELIMITER %L CSV HEADER',
            table_name,
            global_path,
            delimiter
        );
    END
$$ LANGUAGE plpgsql;

---- TESTING SCRIPTS
TRUNCATE peers CASCADE;
CALL import_from_csv ('peers', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//01-init_peers.csv', ',');

TRUNCATE tasks CASCADE;
CALL import_from_csv ('tasks', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//02-init_tasks.csv', ',');

TRUNCATE checks CASCADE;
CALL import_from_csv ('checks', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//03-init_checks.csv', ',');

TRUNCATE p2p CASCADE;
CALL import_from_csv ('p2p', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//04-init_p2p.csv', ',');

TRUNCATE verter CASCADE;
CALL import_from_csv ('verter', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//05-init_verter.csv', ',');

-- SELECT checking_peer, peer FROM checks JOIN p2p ON checks.id = p2p.check_id WHERE state != 'start' and state != 'failure' ORDER BY checking_peer, peer;
-- SELECT checking_peer, peer FROM checks JOIN p2p ON checks.id = p2p.check_id WHERE state != 'start' ORDER BY checking_peer, peer;

TRUNCATE transferred_points CASCADE;
CALL import_from_csv ('transferred_points', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//06-init_transferred_points.csv', ',');

TRUNCATE friends CASCADE;
CALL import_from_csv ('friends', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//07-init_friends.csv', ',');

TRUNCATE recommendations CASCADE;
CALL import_from_csv ('recommendations', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//08-init_recommendations.csv', ',');

TRUNCATE xp CASCADE;
CALL import_from_csv ('xp', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//09-init_xp.csv', ',');

-- SELECT check_id, max_xp FROM checks JOIN verter v on checks.id = v.check_id join tasks t on checks.task = t.title WHERE state != 'start' and state != 'failure';

TRUNCATE time_tracking CASCADE;
CALL import_from_csv ('time_tracking', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/csv//10-init_time_tracking.csv', ',');

---------------------------------------------------------------------------------------------
-- EXPORT TO CSV
---------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE export_to_csv(
    table_name varchar,
    global_path varchar,
    delimiter varchar
) AS $$
    BEGIN
--         Copy (Select * From $1) To $2 With CSV DELIMITER $3 HEADER;
        EXECUTE format(
            'COPY %s TO %L WITH CSV DELIMITER %L HEADER',
            table_name,
            global_path,
            delimiter
        );
    END
$$ LANGUAGE plpgsql;

-- -- TESTING SCRIPTS
TRUNCATE peers CASCADE;
INSERT INTO peers VALUES ('myregree', '1987.10.19');
INSERT INTO peers VALUES ('darrpama', '1988.11.20');
CALL export_to_csv ('peers', '/Users/myregree/Desktop/projects/SQL2_Info21_v1.0-0/src/peers.csv', ',');
