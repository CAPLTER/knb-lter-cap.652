# Ball Lab 2023 arthropod import

This package loads the co-located
`arthropods_2023_ball_lab/652_arthropods_2023BallLab.csv` into existing
`survey200` sweep-net samples. It does not create new sweep-net samples and
does not assume that serial IDs are the same across databases.

## Files

- `prepare_arthropods_2023_ball_lab.R` validates and normalizes the source CSV.
- `import_arthropods_2023_ball_lab.sql` resolves database keys, updates notes,
  and inserts reference and count records.
- `run_import.sh` selects the database, checks the source checksum, runs R,
  invokes SQL, logs results, and defaults to rollback.

Reviewed source SHA-256:

```text
8aeb32dc93625b60e5cfa45826eb18a6d3e8c819eccebdd25e00f82c37170a44
```

## Why R and SQL are both used

R handles transformations that are easier to review outside the database:

- date corrections;
- spelling and synonym corrections;
- removal of terminal `sp` and `sp.`;
- `None` to `Unknown`;
- extraction of replicate numbers;
- numeric and source-shape validation.

SQL handles operations that require current database state:

- reference-taxon lookup and insertion;
- event and sample resolution;
- foreign-key updates;
- collision checks;
- aggregation by resolved sample/taxon;
- sample-note updates and count inserts.

This keeps the database logic focused on relational work while producing a
temporary prepared CSV that can be inspected during development.

## Database selection

The runner accepts any database containing a compatible `survey200` schema:

```bash
./database_imports/arthropods_2023_ball_lab/run_import.sh \
  --database caplter_development
```

The default remains `caplter`. The SQL does not require a particular database
name; it only requires the `survey200` schema and expected tables.

Run and commit against development first:

```bash
./database_imports/arthropods_2023_ball_lab/run_import.sh \
  --database caplter_development \
  --commit
```

After reviewing development results, run a production dry run and then commit:

```bash
./database_imports/arthropods_2023_ball_lab/run_import.sh \
  --database caplter

./database_imports/arthropods_2023_ball_lab/run_import.sh \
  --database caplter \
  --commit
```

`--commit` requires typing `APPLY`.

## Serial IDs

`sweepnet_sample_id` is a serial surrogate key. It is safe to report or join a
resolved ID within one database, but it is not safe to hardcode that ID and
expect it to identify the same logical sample in development and production.

The import therefore locates samples using:

- `site_code`;
- `research_focus = 'survey200'`;
- corrected sampling date;
- sweep-net sample type;
- normalized vegetation taxon;
- replicate rank among matching samples.

Serial IDs appear only in reconciliation output and audit notes after they have
been resolved in the selected database.

## Approved transformations

### Sampling dates

| Site | Incoming date | Sampling-event date |
|---|---|---|
| AB22 | 2022-05-31 | 2023-05-31 |
| E12 | 2023-03-20 | 2023-03-30 |
| F12 | 2023-03-29 | 2023-03-30 |
| X15 | 2023-04-14 | 2023-04-13 |
| V20 | 2023-04-19 | 2023-04-14 |
| AB17 | 2023-06-03 | 2023-06-06 |

Each affected sample receives a note containing the incoming and selected
sampling-event dates.

### Taxonomy

- Arthropod `None` becomes `Unknown`.
- Add insect scientific names `Heteroptera`, `Opiliones`, and
  `Trombidiformes`; no other insect fields are populated.
- Add vegetation scientific name `Encelia virginensis`.
- Re-point only the AB10 `2023-04-25` Encelia sample to
  `Encelia virginensis`; preserve generic historical Encelia records.
- Remove terminal `sp` and `sp.` from substrata.
- AA21 `Tecoma sp.` becomes `Tecoma stans`.
- `Cascabela thevetia` becomes `Thevetia peruviana`.
- `Encilia farinosa` becomes `Encelia farinosa`.
- `Prosopsis sp.` becomes `Prosopis`.
- `Salvia rosmarinus` maps to `Rosmarinus officinalis` and is documented in
  sample notes.

### Duplicate plants

- `#1`, `#2`, and `#3` select the correspondingly ordered matching sample.
- Unnumbered duplicates use the first matching sample and receive an ambiguity
  note.
- At AC19, only `Oleander#2` uses the second Nerium sample; all other incoming
  Nerium rows use the first.
- Indistinguishable rows resolving to the same sample/taxon are summed. This
  produces two aggregations at AC19 and two at AA19.

### Notes and zero counts

- Immature and winged values are recorded by insect taxon in sample notes.
- Literal `NA` values are omitted; numeric zeroes are retained.
- Existing notes are preserved.
- The AB22 Lactuca/Unknown count remains zero and receives:
  `No organisms were found in this collected sample.`
- The AC22 total 1 / immature 2 observation remains in notes as approved.
- The count-table `immature` column remains null.

The combined notes can be longer than the current `varchar(150)`. The import
drops the retired
`survey200.public_lens_survey200_insect_sweepnet_samples` view and widens
`sweepnet_samples.notes` to `text`. Both changes roll back during a dry run.

## Acceptance criteria

The transaction aborts unless it confirms:

| Check | Expected |
|---|---:|
| Source and mapped rows | 384 |
| Inserted count rows after aggregation | 380 |
| Samples receiving counts and notes | 111 |
| Total arthropod abundance | 5,098 |
| Explicit zero observations | 1 |
| Existing target count collisions | 0 |

## Dry-run behavior

Without `--commit`, the target-table transaction ends with `ROLLBACK`.
PostgreSQL sequences are not transactional, so the wrapper snapshots and
restores the three affected sequence states when the dry run exits, including
after an SQL error. This package assumes, as agreed, that another writer is not
running concurrently.

Logs are written under `logs/`. The temporary prepared CSV is removed when the
runner exits.

## Required access

The PostgreSQL user needs:

- `CONNECT` on the selected database;
- `USAGE` on schema `survey200`;
- `SELECT`, `INSERT`, `UPDATE`, `ALTER`, and `DROP` as used by the script;
- `USAGE` on the affected sequences.

Use normal libpq configuration (`PGHOST`, `PGPORT`, `PGUSER`, `PGSERVICE`, or
`~/.pgpass`). Do not place passwords in repository files.

## Reruns

Reference additions and the AB10 foreign-key update are idempotent. The count
load deliberately aborts if any proposed sample/taxon pair already exists, so
a successful import cannot be rerun accidentally.
