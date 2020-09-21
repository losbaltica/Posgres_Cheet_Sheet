DO
$$
    DECLARE
        schema text;
        schemaOwner text := 'schema_owner';
        newSchemaUser text := 'new_schema_user';
    BEGIN
        FOR schema IN  (SELECT schema_name
                                 FROM information_schema.schemata
                                 WHERE schema_owner = schemaOwner)
            LOOP
                EXECUTE 'GRANT USAGE ON SCHEMA ' || schema || ' TO ' || newSchemaUser || ';';
                RAISE NOTICE 'Usage permission granted on schema: %', schema;
            end loop;
    end;
$$;
