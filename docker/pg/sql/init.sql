CREATE OR REPLACE FUNCTION generate_channel_name(table_name text) RETURNS text AS
$$
BEGIN
  RETURN 'channel_' || table_name;
END;
$$
  LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION table_change_notify() RETURNS trigger AS
$$
DECLARE
  channel text;
BEGIN
  channel := generate_channel_name(TG_TABLE_NAME);
  PERFORM pg_notify(channel, TG_OP || ',' || TG_TABLE_NAME || ',' || NEW.id);
  RETURN NEW;
END;
$$
  LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_trigger_for_all_tables_in_schema(schema_name TEXT) RETURNS VOID AS $$
DECLARE
  table_name TEXT;
BEGIN
  FOR table_name IN SELECT table_name FROM information_schema.tables WHERE table_schema = schema_name
    LOOP
      EXECUTE format('CREATE TRIGGER %s_notify_trigger AFTER INSERT OR UPDATE OR DELETE ON %s FOR EACH ROW EXECUTE PROCEDURE notify_trigger_function();', table_name, table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT create_trigger_for_all_tables_in_schema('public');

