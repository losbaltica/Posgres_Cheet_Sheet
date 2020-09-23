DO
$$
BEGIN
    RETURN st_difference(geom_a, geom_b);
EXCEPTION
    WHEN OTHERS THEN
        BEGIN
            RETURN st_difference(ST_Buffer(geom_a, 0.0000001), ST_Buffer(geom_b, 0.0000001));
        EXCEPTION
            WHEN OTHERS THEN
                RETURN ST_GeomFromText('POLYGON EMPTY');
        END;
END
$$;
