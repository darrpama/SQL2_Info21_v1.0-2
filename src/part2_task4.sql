CREATE OR REPLACE FUNCTION fnc_trg_xp_max() RETURNS TRIGGER AS $xp$
    DECLARE
        p2pRows int;
        verterRows int;
        xpAmount int;
    BEGIN
        -- Количество XP не превышает максимальное доступное для проверяемой задачи
        SELECT max_xp INTO xpAmount FROM tasks
            INNER JOIN checks c on tasks.title LIKE c.task
            INNER JOIN xp x on c.id = x.check_id;
        IF (xpAmount > NEW.xp_amount)
        THEN
            RAISE EXCEPTION 'Xp [id:%] is greater than it should be',
            NEW.xp_amount;
        END IF;

        -- Поле Check ссылается на успешную проверку Если запись не прошла проверку, не добавлять её в таблицу.
        -- Проверка считается успешной, если соответствующий P2P этап успешен, а этап Verter успешен, либо отсутствует.
        SELECT count(id) INTO p2pRows FROM p2p
        WHERE check_id = NEW.check_id AND state = 'success';
        IF (p2pRows = 0)
        THEN
            RAISE EXCEPTION 'P2P check [id:%] is not success',
            NEW.check_id;
        END IF;

        SELECT count(id) INTO verterRows FROM verter
        WHERE check_id = NEW.check_id AND state = 'success';
        IF (verterRows = 0) THEN
            RAISE EXCEPTION 'Verter check [id:%] is not success',
            NEW.check_id;
        END IF;
        -- Проверка считается неуспешной, хоть один из этапов неуспешен.
        --     Проверки, в которых ещё не завершился этап P2P,
        --     или этап P2P успешен, но ещё не завершился этап Verter,
        --     не относятся ни к успешным, ни к неуспешным.
        RETURN NEW;
    END;
$xp$ LANGUAGE plpgsql;

CREATE TRIGGER trg_xp_max
    BEFORE INSERT OR UPDATE ON xp
    FOR EACH ROW EXECUTE PROCEDURE fnc_trg_xp_max();
