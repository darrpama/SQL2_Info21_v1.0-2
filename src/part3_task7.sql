DELETE FROM tasks WHERE title = 'SmartCalc_v2.0';
INSERT INTO tasks VALUES ('CPP3_SmartCalc_v2.0', 'CPP1_s21_matrix+', 600);


CREATE OR REPLACE FUNCTION fn_get_peers_finished_block(block VARCHAR)
    RETURNS TABLE(peer VARCHAR, date DATE)
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
        WITH successful_checks AS
            (SELECT DISTINCT peer, task,
                 FIRST_VALUE(check_date) OVER (PARTITION BY peer, task ORDER BY check_date) as date
             FROM (SELECT * FROM checks WHERE task SIMILAR TO CONCAT(block, '[0-9]%')) as c
                   LEFT JOIN p2p p ON c.id = p.check_id
                   LEFT JOIN verter v ON c.id = v.check_id
            WHERE p.state = 'success' AND (v.state IS NULL OR v.state = 'success'))
        SELECT peer, MAX(date) as date FROM successful_checks GROUP BY peer
        HAVING COUNT(task) = (SELECT COUNT(title) FROM tasks WHERE title SIMILAR TO CONCAT(block, '[0-9]%'));
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_get_peers_finished_block('C');

DELETE FROM tasks WHERE title = 'CPP3_SmartCalc_v2.0'; -- нужно поправить табличку, если нет конфликтов с тестами других функций
INSERT INTO tasks VALUES ('SmartCalc_v2.0', 'CPP1_s21_matrix+', 600);
-- еще нужно добавить связанной информации в checks и p2p, чтобы хоть кто-то закрыл блок