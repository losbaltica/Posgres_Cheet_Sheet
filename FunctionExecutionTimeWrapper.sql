--
-- Name: nm_execution_time_raise(character varying); Type: FUNCTION; Schema: f_analysis; Owner: postgres
--

CREATE FUNCTION execution_time_raise(function_name character varying) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    StartTime  timestamptz;
    EndTime    timestamptz;
    Delta      double precision;
    TimeFormat varchar;
BEGIN
    StartTime := clock_timestamp();
    EXECUTE function_name;
    EndTime := clock_timestamp();
    Delta := (extract(epoch from EndTime) - extract(epoch from StartTime));
    TimeFormat := to_char(Delta, 'FM999999999.000');
    RAISE NOTICE 'Function: % executed in % secs', function_name, TimeFormat;
END
$$;
