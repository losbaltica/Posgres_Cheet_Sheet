-- Jim Jones
-- https://stackoverflow.com/a/70516940/5935388

CREATE TABLE split_line AS
WITH j AS (
  SELECT id, ST_MakeLine(j.geom,LEAD(j.geom) OVER w) AS line
  FROM source_line, ST_DumpPoints(geom) j (path,geom)
  WINDOW w AS (PARTITION BY id ORDER BY j.path
               ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)
)
SELECT * FROM j;
