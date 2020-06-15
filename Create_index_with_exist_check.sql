-------------------------------------------------------------------------------
------------------------ Create index with exist check ------------------------
-------------------------------------------------------------------------------
--
-- Name: create_index_with_exist_check(schema_table_name character varying,
-- column_name character varying, geom_index character varying); Type: FUNCTION; Schema: f_analysis; Owner: postgres
--
CREATE OR REPLACE FUNCTION create_index_with_exist_check(schema_table_name varchar, column_name varchar,
                                                   geom_index bool = false)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    index_exits      BOOLEAN := false;
    geom_index_query VARCHAR := '';
BEGIN

    RAISE NOTICE 'New index for %', schema_table_name;

    -- Check if index on that column already exists
    SELECT INTO index_exits exists( SELECT
    FROM (
             SELECT indrelid::regclass::text                                  AS table_name
                  , idx_columns
                  , indexrelid::regclass::text                                AS index
                  , pg_size_pretty(pg_table_size(indexrelid::regclass::text)) AS size
             FROM pg_index i,
                  LATERAL (
                      SELECT string_agg(attname, ', ') AS idx_columns
                      FROM pg_attribute
                      WHERE attrelid = i.indrelid
                        AND attnum = ANY (i.indkey) -- 0 excluded by: indexprs IS NULL
                      ) a) b
    WHERE b.table_name = schema_table_name
      AND b.idx_columns = column_name);


    IF index_exits THEN
        -- If true - Return function if exist
        RAISE NOTICE 'Index already exist. Skipping...';
    ELSE
        RAISE NOTICE 'Index not exist. Start creating...';
        -- If false - Create index
        IF geom_index  THEN
            SELECT INTO geom_index_query 'USING GIST';
        end if;

        EXECUTE 'CREATE INDEX ON ' || schema_table_name || ' ' || geom_index_query || ' (' || column_name || ')';
        RAISE NOTICE 'Index on column % created', column_name;
    end if;
END $$;
