
CREATE OR REPLACE FUNCTION clean_schema_indexes_primary(schema_name varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    index_drop_arr varchar[];
    t              varchar;
BEGIN
    RAISE NOTICE 'Start removing indexes from schema %', schema_name;

    SELECT INTO index_drop_arr array_agg(c.oid::regclass::varchar || '#' || t.relname)
    FROM pg_catalog.pg_class c
             JOIN pg_catalog.pg_index i ON (c.oid = i.indexrelid)
             JOIN pg_class t ON (i.indrelid = t.oid)
             JOIN pg_namespace n ON (c.relnamespace = n.oid)
    WHERE n.nspname = schema_name -- and schema name goes here
      AND EXISTS(
            SELECT 1
            FROM pg_catalog.pg_depend d
            WHERE
                d.classid = 'pg_catalog.pg_class' ::REGCLASS:: OID
              AND d.objsubid = 0
              AND d.deptype = 'e'
            LIMIT 1);

    FOREACH t IN ARRAY index_drop_arr
        LOOP
            BEGIN

                RAISE NOTICE 'Input index %', split_part(t, '#', 1);
                RAISE NOTICE 'Input table %', split_part(t, '#', 2);

                EXECUTE 'alter table ' || schema_name || '.' || split_part(t, '#', 2) || '
                    drop constraint ' || split_part(split_part(t, '#', 1), '.', 2) || ';';

                RAISE NOTICE 'Drop constrain done %', split_part(split_part(t, '#', 1), '.', 2);

                EXECUTE 'alter table ' || schema_name || '.' || split_part(t, '#', 2) || ' alter column _fid_ drop not null;';

                RAISE NOTICE 'Performed index drop %', split_part(t, '#', 2);

                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE NOTICE 'Foreign key contrain on %. Skipping...', t;
                        CONTINUE;
            END;
        END loop;

    RAISE NOTICE 'Finish indexes drop for schema %', schema_name;

END
$$;
