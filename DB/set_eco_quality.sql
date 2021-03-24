/*Default value for eco's quality is null. The chosen array will be set as FALSE. 
Keep it in mind when resetting this value to a different array of eco */
DO
$do$
DECLARE
   sch text := 'public';  
   tbl text;
BEGIN
   FOR tbl IN
SELECT tablename FROM pg_catalog.pg_tables
      WHERE  schemaname = 'public'
      AND    tablename LIKE 'protein_%'
      AND    tablename NOT LIKE 'protein_go%' 
	   AND    tablename NOT LIKE 'protein_score' 
   LOOP
      EXECUTE format($$UPDATE %I.%I 
                       SET quality = FALSE
                       WHERE eco LIKE ANY(array['ECO:0000501',
                       'ECO:0000203','ECO:0000209',
                       'ECO:0000348','ECO:0000350',
                       'ECO:0000347','ECO:0000331',
                       'ECO:0000213','ECO:0000246',
                       'ECO:0000254','ECO:0000313',
                       'ECO:0000259','ECO:0000256',
                       'ECO:0000258','ECO:0000210',
                       'ECO:0000211','ECO:0000248',
                       'ECO:0000265','ECO:0000249',
                       'ECO:0000251','ECO:0000261',
                       'ECO:0000263','ECO:0000332']) 
                       $$, sch, tbl); 
   END LOOP;
END
$do$;

