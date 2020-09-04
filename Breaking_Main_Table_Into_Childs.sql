DO
$do$
    DECLARE
        parent_table text := 'parent';
        child_table text := 'child';
        storage_key_table text := 'breaking_point_storage';
        circuit varchar;
    BEGIN

        FOR circuit IN
            SELECT breaking_point_key
            FROM storage_key_table
            LOOP
                RAISE NOTICE 'Start processing - %', breaking_point;
                EXECUTE 'CREATE TABLE ' || child_table ||'_' || circuit || ' () ' ||
                        ' INHERITS (' || parent_table || ');';
                RAISE NOTICE 'Table created';
                EXECUTE (
                            'INSERT INTO ' || child_table || '_' || circuit || ' ' ||
                            'SELECT * FROM ' || parent_table ||
                            ' WHERE breaking_point_key = ''' || circuit || '''::text;'
                    );
                RAISE NOTICE 'Rows inserted';
                EXECUTE (
                            'CREATE INDEX ON ' || child_table || '_' || circuit || ' ' ||
                            '(breaking_point_key);'
                    );
                RAISE NOTICE 'Index created - primary key';
                EXECUTE (
                            'CREATE INDEX ON fa_vegetation.canopy_' || circuit || ' ' ||
                            'USING GIST (geom);'
                    );
                RAISE NOTICE 'Index created - geom';
                RAISE NOTICE 'Finish processing - %', circuit;
            END LOOP;
    END
$do$; -- LANGUAGE plpgsql is the default
