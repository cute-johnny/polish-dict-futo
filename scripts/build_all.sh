#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Rebuild both Polish dictionaries from scratch.
#   usage: scripts/build_all.sh [WORK_DIR]   (default: ./work)
# Output: WORK_DIR/out/main_pl_merged_v2.dict   (format 202, <16 MiB, works in stock FUTO/HeliBoard)
#         WORK_DIR/out/main_pl_large_v203.dict  (format 203, full merge, needs the patched FUTO fork)
# Needs: bash, curl, unzip, python3, java + javac (17+), ~8 GB RAM, ~1 GB disk.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(realpath -m "${1:-$HERE/work}")"
CAPPED_EXTRA="${CAPPED_EXTRA:-250000}"   # polimorfologik-only forms added to the <16 MiB build
mkdir -p "$WORK"/{src,out,cls}
cd "$WORK"

# 1. Sources ---------------------------------------------------------------
[ -f src/polimorfologik-2.1.zip ] || curl -fL -o src/polimorfologik-2.1.zip \
  https://github.com/morfologik/polimorfologik/releases/download/2.1/polimorfologik-2.1.zip
[ -f src/pl.combined ] || curl -fL -o src/pl.combined \
  https://codeberg.org/Helium314/aosp-dictionaries/raw/branch/main/wordlists/main_pl__experimental.combined
[ -f src/dicttool_aosp.jar ] || curl -fL -o src/dicttool_aosp.jar \
  https://codeberg.org/Helium314/aosp-dictionaries/raw/branch/main/dicttool_aosp.jar
[ -f src/pm/polimorfologik-2.1.txt ] || unzip -o -q src/polimorfologik-2.1.zip -d src/pm

# 2. Word sets ---------------------------------------------------------------
# polimorfologik line format: lemma;form;tags   (form = field 2)
cut -d';' -f2 src/pm/polimorfologik-2.1.txt | LC_ALL=C sort -u > pm_forms.txt
grep '^ word=' src/pl.combined | sed -E 's/^ word=([^,]*),f=([0-9]+).*/\1\t\2/' > heli_words.tsv
cut -f1 heli_words.tsv | LC_ALL=C sort -u > heli_forms.txt
LC_ALL=C comm -13 heli_forms.txt pm_forms.txt | grep -v '[0-9. ]' > pm_only.txt || true
echo "HeliBoard: $(wc -l < heli_forms.txt)  polimorfologik: $(wc -l < pm_forms.txt)  pm-only: $(wc -l < pm_only.txt)"

# 3. Word lists (.combined) -----------------------------------------------------
# pm-only forms get f=10: below HeliBoard's floor (15) so corpus-attested words always rank first.
header() { echo "dictionary=main:pl,locale=pl,description=$1,date=$(date +%s),version=$2"; }

{ header "Polski (HeliBoard experimental + polimorfologik 2.1)" 21
  tail -n +2 src/pl.combined
  sed 's/^/ word=/; s/$/,f=10/' pm_only.txt; } > main_pl_full.combined

python3 -I "$HERE/scripts/rank.py" heli_words.tsv src/pm/polimorfologik-2.1.txt pm_ranked.tsv
{ header "Polski (HeliBoard experimental + polimorfologik 2.1)" 20
  tail -n +2 src/pl.combined
  head -n "$CAPPED_EXTRA" pm_ranked.tsv | cut -f1 | sed 's/^/ word=/; s/$/,f=10/'; } > main_pl_capped.combined

# 4. Patched encoder -----------------------------------------------------------
javac -nowarn -cp src/dicttool_aosp.jar -d cls \
  "$HERE"/encoder/src/com/android/inputmethod/latin/makedict/*.java
DT=(java -Xmx6g -cp "cls:src/dicttool_aosp.jar" com.android.inputmethod.latin.dicttool.Dicttool)

# 5. Compile dictionaries ------------------------------------------------------
# Normal mode: format 202. The patched encoder fails if the result would exceed 16 MiB.
"${DT[@]}" makedict -s main_pl_capped.combined -d out/main_pl_merged_v2.dict > out/build_v2.log 2>&1
# Large mode: format 203 with 4-byte pointers.
java -Xmx6g -Ddicttool.large=true -cp "cls:src/dicttool_aosp.jar" \
  com.android.inputmethod.latin.dicttool.Dicttool \
  makedict -s main_pl_full.combined -d out/main_pl_large_v203.dict > out/build_v203.log 2>&1

# 6. Verify ------------------------------------------------------------------
ls -l out/*.dict
for d in out/main_pl_merged_v2.dict out/main_pl_large_v203.dict; do python3 -I "$HERE/scripts/check_dict.py" "$d"; done
size=$(stat -c %s out/main_pl_merged_v2.dict)
[ "$size" -lt 16777216 ] || { echo "ERROR: v2 dict is $size bytes (must be < 16 MiB)"; exit 1; }
echo "Done."
