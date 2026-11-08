-- Optional large schema for completion and ER-diagram work: 500 tables, about
-- 7,500 columns and one foreign key per non-base table, in schema "large".
-- Load with: docker compose -f dev/docker-compose.yml --profile large-schema up postgres-large-seed
DROP SCHEMA IF EXISTS large CASCADE;
CREATE SCHEMA large;

DO $$
DECLARE
  domains text[] := ARRAY['customer','order','invoice','product','payment','shipment','supplier','employee','account','ticket',
                          'campaign','warehouse','address','contract','session','document','category','inventory','refund','review'];
  suffixes text[] := ARRAY['','_item','_line','_history','_log','_status','_note','_tag','_audit','_archive','_map','_setting',
                           '_event','_detail','_summary','_type','_group','_rule','_batch','_queue','_cache','_draft','_link','_stat','_config'];
  n_domains int := array_length(domains, 1);
  n_tables int := 500;
  tname text;
  ref_domain text;
BEGIN
  FOR i IN 0 .. n_tables - 1 LOOP
    tname := domains[(i % n_domains) + 1] || suffixes[(i / n_domains) + 1];
    EXECUTE format('CREATE TABLE large.%I (
      id bigserial PRIMARY KEY,
      name text NOT NULL,
      status text NOT NULL DEFAULT ''new'',
      created_at timestamptz NOT NULL DEFAULT now(),
      updated_at timestamptz NOT NULL DEFAULT now(),
      amount numeric(12,2),
      quantity integer NOT NULL DEFAULT 0,
      notes text,
      is_active boolean NOT NULL DEFAULT true,
      code varchar(32),
      email text,
      price numeric(12,2),
      sort_order integer NOT NULL DEFAULT 0,
      owner_id bigint
    )', tname);
    IF i >= n_domains THEN
      ref_domain := domains[((i + 3) % n_domains) + 1];
      EXECUTE format('ALTER TABLE large.%I ADD COLUMN %I bigint REFERENCES large.%I (id)', tname, ref_domain || '_id', ref_domain);
      EXECUTE format('CREATE INDEX ON large.%I (%I)', tname, ref_domain || '_id');
    END IF;
  END LOOP;
END $$;

ANALYZE;
