CREATE OR REPLACE FUNCTION h_export.clean_schema_indexes(schema_name varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    index_drop_arr varchar[];
    t              varchar;
    index_bites    bigint;
    index_size_arr bigint[];
    index_size     text;
BEGIN
    RAISE NOTICE 'Start removing indexes from schema %', schema_name;

    SELECT INTO index_drop_arr array_agg(c.oid::regclass::varchar)
    FROM pg_catalog.pg_class c
             JOIN pg_catalog.pg_index i ON (c.oid = i.indexrelid)
             JOIN pg_class t ON (i.indrelid = t.oid)
             JOIN pg_namespace n ON (c.relnamespace = n.oid)
    WHERE c.relkind = 'i'
      AND NOT EXISTS(
            SELECT 1
            FROM pg_catalog.pg_constraint
            WHERE conindid = c.oid
              AND contype != 'f'
            LIMIT 1)
      AND n.nspname = schema_name -- and schema name goes here
      AND t.relkind IN ('r' :: "char", 'm' :: "char", 'p' :: "char")
      AND EXISTS(
            SELECT 1
            FROM pg_catalog.pg_depend d
            WHERE
--             d.objid = t.oid AND
                d.classid = 'pg_catalog.pg_class' ::REGCLASS:: OID
              AND d.objsubid = 0
              AND d.deptype = 'e'
            LIMIT 1);

    FOR t IN SELECT unnest(index_drop_arr)
        LOOP
            BEGIN
                SELECT size
                INTO index_bites
                FROM (
                         SELECT indexrelid::regclass::varchar               AS index
                              , pg_table_size(indexrelid::regclass::bigint) AS size
                         FROM pg_index i,
                              LATERAL (
                                  SELECT string_agg(attname, ', ') AS idx_columns
                                  FROM pg_attribute
                                  WHERE attrelid = i.indrelid
                                    AND attnum = ANY (i.indkey) -- 0 excluded by: indexprs IS NULL
                                  ) a) b
                WHERE b.index = t;
--                 RAISE NOTICE '%', index_bites;
                index_size_arr := array_append(index_size_arr, index_bites);
--                 RAISE NOTICE '%', index_size_arr;
                EXECUTE 'DROP INDEX ' || t || ';';
                RAISE NOTICE 'Performed index drop %', t;

            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'Foreign key contrain on %. Skipping...', t;
                    CONTINUE;
            END;
        END loop;

    IF array_length(index_size_arr, 1) > 0 THEN
        SELECT INTO index_size pg_size_pretty(sum(s))::text FROM unnest(index_size_arr) s;
        RAISE NOTICE 'Finish indexes drop for schema %. Space unblocked: %', schema_name, index_size;
    end if;

END
$$;
