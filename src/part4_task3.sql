-- TASK PROCEDURE
CREATE OR REPLACE PROCEDURE proc_kill_all_triggers(a OUT INT) AS $$
DECLARE
    result INT;
    triggerName RECORD;
BEGIN
    FOR triggerName IN SELECT * FROM information_schema.triggers AS t
        WHERE t.trigger_schema = 'public'
        AND t.trigger_catalog = (SELECT current_database()) LOOP
            RAISE NOTICE 'Dropping trigger: % on table: %', triggerName.trigger_name, triggerName.event_object_table;
            EXECUTE 'DROP TRIGGER IF EXISTS ' || triggerName.trigger_name || ' ON ' || triggerName.event_object_table || ';';
    END LOOP;

    a := result;
END;
$$ LANGUAGE plpgsql;


-- PREPARE TRIGGER FOR TEST
CREATE OR REPLACE FUNCTION test_trigger_func() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
	RAISE NOTICE 'trigger ran';
	RETURN NEW;
END
$$;

CREATE TRIGGER test_trigger
  BEFORE UPDATE ON peers
  FOR EACH ROW
  EXECUTE PROCEDURE test_trigger_func();

-- TESTING PROCEDURE
DO $$
DECLARE
    a INT;
BEGIN
    CALL proc_kill_all_triggers(a);
    RAISE NOTICE '%', a;
END;$$;

-- ASSERT RESULT
SELECT * FROM information_schema.triggers AS t
        WHERE t.trigger_schema = 'public'
        AND t.trigger_catalog = (SELECT current_database());
