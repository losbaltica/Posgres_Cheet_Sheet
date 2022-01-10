DO
$$
    DECLARE
        schemaTableName text;
        schemaOwner text := 'schema_owner';
        newSchemaUser text := 'new_schema_user';
        permissionLevel text := 'permission_level';
    BEGIN
        FOR schemaTableName IN  (SELECT '"' || schemaname || '"."' || tablename || '"'
                                FROM pg_tables WHERE tableowner = schemaOwner)
            LOOP
                EXECUTE 'GRANT ' || permissionLevel || ' ON TABLE ' || schemaTableName || ' TO ' || newSchemaUser || ';';
                RAISE NOTICE 'Usage permission granted on table: %', schemaTableName;
            end loop;
    end;
$$;
