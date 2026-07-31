#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "${script_dir}/../.." && pwd)"
sql_file="${script_dir}/import_arthropods_2023_ball_lab.sql"
prepare_file="${script_dir}/prepare_arthropods_2023_ball_lab.R"
source_csv="${script_dir}/652_arthropods_2023BallLab.csv"
prepared_csv="${script_dir}/.prepared_arthropods_2023_ball_lab.csv"
expected_sha256="8aeb32dc93625b60e5cfa45826eb18a6d3e8c819eccebdd25e00f82c37170a44"

database="caplter"
apply="false"
sequence_state=""

usage() {
  printf '%s\n' \
    'Usage: run_import.sh [--database NAME] [--commit]' \
    '' \
    'Examples:' \
    '  run_import.sh --database caplter_dev' \
    '  run_import.sh --database caplter_dev --commit' \
    '' \
    'Without --commit, the SQL transaction rolls back.'
}

while (($# > 0)); do
  case "$1" in
    --database)
      if (($# < 2)); then
        echo "ERROR: --database requires a value" >&2
        exit 2
      fi
      database="$2"
      shift 2
      ;;
    --commit)
      apply="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for required_file in "$source_csv" "$prepare_file" "$sql_file"; do
  if [[ ! -f "$required_file" ]]; then
    echo "ERROR: required file not found: $required_file" >&2
    exit 1
  fi
done

actual_sha256="$(sha256sum "$source_csv" | awk '{print $1}')"
if [[ "$actual_sha256" != "$expected_sha256" ]]; then
  echo "ERROR: source CSV differs from the reviewed file." >&2
  echo "Expected: $expected_sha256" >&2
  echo "Actual:   $actual_sha256" >&2
  exit 1
fi

restore_sequences() {
  local veg_last veg_called insect_last insect_called count_last count_called

  if [[ -z "$sequence_state" ]]; then
    return
  fi

  IFS='|' read -r \
    veg_last veg_called \
    insect_last insect_called \
    count_last count_called <<< "$sequence_state"

  for value in "$veg_last" "$insect_last" "$count_last"; do
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
      echo "ERROR: invalid sequence snapshot: $value" >&2
      return 1
    fi
  done

  for value in "$veg_called" "$insect_called" "$count_called"; do
    if [[ "$value" != "t" && "$value" != "f" ]]; then
      echo "ERROR: invalid sequence snapshot flag: $value" >&2
      return 1
    fi
  done

  psql -X --dbname "$database" --command "
    SELECT
      setval(
        'survey200.vegetation_taxon_list_vegetation_taxon_id_seq',
        ${veg_last},
        '${veg_called}'::boolean
      ),
      setval(
        'survey200.insect_taxon_list_insect_taxon_id_seq',
        ${insect_last},
        '${insect_called}'::boolean
      ),
      setval(
        'survey200.sweepnet_sample_insect_counts_insect_count_id_seq',
        ${count_last},
        '${count_called}'::boolean
      );
  " >/dev/null
}

cleanup() {
  local status=$?
  trap - EXIT

  rm -f -- "$prepared_csv"

  if [[ "$apply" == "false" && -n "$sequence_state" ]]; then
    if ! restore_sequences; then
      echo "ERROR: failed to restore dry-run sequence state." >&2
      exit 1
    fi
  fi

  exit "$status"
}
trap cleanup EXIT

if [[ "$apply" == "true" ]]; then
  echo "This will modify ${database}.survey200."
  echo "Expected: 380 count rows, 111 samples, total abundance 5098."
  read -r -p "Type APPLY to continue: " confirmation
  if [[ "$confirmation" != "APPLY" ]]; then
    echo "Import cancelled."
    exit 1
  fi
else
  echo "Running a transactional dry run against database: ${database}"
  sequence_state="$(
    psql \
      -X \
      --dbname "$database" \
      --tuples-only \
      --no-align \
      --field-separator '|' \
      --command "
        SELECT
          vegetation.last_value,
          vegetation.is_called,
          insect.last_value,
          insect.is_called,
          insect_count.last_value,
          insect_count.is_called
        FROM
          survey200.vegetation_taxon_list_vegetation_taxon_id_seq vegetation
        CROSS JOIN survey200.insect_taxon_list_insect_taxon_id_seq insect
        CROSS JOIN
          survey200.sweepnet_sample_insect_counts_insect_count_id_seq insect_count;
      "
  )"
fi

Rscript "$prepare_file" "$source_csv" "$prepared_csv"

log_dir="${script_dir}/logs"
mkdir -p "$log_dir"
timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
mode="dry-run"
if [[ "$apply" == "true" ]]; then
  mode="commit"
fi
log_file="${log_dir}/${timestamp}-${database}-${mode}.log"

cd -- "$repo_dir"

psql \
  -X \
  --dbname "$database" \
  --set "apply=${apply}" \
  --file "$sql_file" \
  2>&1 | tee "$log_file"

echo "Log saved to: $log_file"
