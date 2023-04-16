CREATE OR REPLACE FUNCTION fn_tasks_parent()
    RETURNS TABLE(Task VARCHAR, PrevCount BIGINT)
AS $$
BEGIN
    RETURN QUERY
        WITH RECURSIVE t(title, parent_task) AS
            (SELECT title as task, parent_task as parent FROM tasks
            UNION ALL
            SELECT t1.title, t2.parent_task FROM t as t1, tasks as t2
            WHERE t1.parent_task = t2.title)
        SELECT title, COUNT(parent_task) FROM t GROUP BY title;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fn_tasks_parent()

