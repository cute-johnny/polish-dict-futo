# Polish dictionary for FUTO Keyboard (HeliBoard + polimorfologik)

This folder contains a Polish swipe/prediction dictionary for FUTO Keyboard, plus a
FUTO Keyboard fork that can load dictionaries larger than 16 MiB.
**Status (2026-11-20): working.** The user tested it on their phone (Xiaomi, `mondrian`).

## What's here

| Path | What it is |
|---|---|
| `dist/main_pl_merged_v2.dict` | 16.19 MB, format 202. HeliBoard's Polish word list plus the 250k most useful polimorfologik forms. Works in **stock** FUTO and HeliBoard. |
| `dist/main_pl_large_v203.dict` | 28.6 MB, format 203. Full merge: 4,957,523 words. Works **only** in the patched FUTO fork. |
| `dist/apk/…/android-keyboard-unstable-release.apk` | Patched FUTO Keyboard, built by GitHub Actions run #1. Installs as "FUTO Keyboard Unstable" (`org.futo.inputmethod.latin.unstable`) next to normal FUTO. |
| `futo-keyboard/` | Sparse, blobless clone of the fork: github.com/cute-johnny/android-keyboard, branch `large-dictionaries`. |
| `futo-patch/0001-…`, `0002-…` | The fork's two commits as standalone git patches (`git am` onto upstream FUTO). |
| `encoder/` | Patched AOSP dictionary encoder (2 Java classes) that writes format 203. `large-addresses.patch` is the diff against AOSP. |
| `scripts/build_all.sh` | Rebuilds both dictionaries from the original sources. |
| `scripts/rank.py` | Picks which polimorfologik forms go into the size-limited build. |
| `scripts/check_dict.py` | Reads a `.dict` like the keyboard does and counts words. Checks that every pointer is valid. |
| `docs/` | Local only, not in git: a screenshot of the original bug (an oversized dictionary gives garbage suggestions). It contains private chat content. |
| `third-party-licenses/` | License files of the data sources. |
| `AGENT.md` | Full technical notes for a future agent or developer. |
| `CREDITS.md`, `LICENSES.md` | Thanks, attributions and the licensing of each part. |
| `LICENSE` | GNU GPL v3.0: the license for this project's own work and the dictionaries. |

SHA-256:
```
11efc8acc2482cd4e73712f9f481b53b4f947349f68de2c87fb152bd3622fbf0  dist/main_pl_merged_v2.dict
5002b95dfdf4d5834a2a99aea33dd6dfc7a480e4fbaf45d2ced3961790a8e020  dist/main_pl_large_v203.dict
73b22452e9c5a716164b6afd89baaa4e11ba66b8d4cde1077b4113f83a67a9d3  dist/apk/futo-keyboard-large-dict-1/android-keyboard-unstable-release.apk
```

## How it was made

1. **Two sources.**
   - **HeliBoard `main_pl__experimental`** word list: 2.6M words. It has real frequencies from the Leipzig corpora and 174,550 bigrams (word pairs).
   - **polimorfologik 2.1:** 4.67M inflected forms, no frequencies, last updated 2016.
   - The two lists share 2.31M words. 2.36M forms exist only in polimorfologik.
2. **Merge.** HeliBoard entries are kept unchanged. polimorfologik-only forms are added with frequency 10, below HeliBoard's lowest value (15), so words seen in real text always rank first. Entries containing digits, dots or spaces are dropped.
3. **Size limit found.** The first full merge was 28.4 MB. The AOSP format stores pointers in at most 3 bytes, so a file can't exceed 16,777,215 bytes. The stock `dicttool` writes truncated pointers without any warning. FUTO then showed garbage suggestions (`docs/`) and crashed when swiping.
4. **Fix A, within the limit** (`main_pl_merged_v2.dict`). polimorfologik-only forms are ranked by how often their base word appears in HeliBoard's frequency data. Only the top 250k are added, which gives 16.19 MB.
5. **Fix B, new format 203** (`main_pl_large_v203.dict` plus the fork). It's the same layout as 202, except that the "3-byte" pointer type is stored in 4 bytes. FUTO's native reader was patched to load it (14 files, about 60 lines). Stock readers reject 203 as an unknown version instead of misreading it. The APK is built in GitHub Actions.
6. **Verification.** `check_dict.py` reads both files like the keyboard does: every word and every pointer. As a control, it counts HeliBoard's original dictionary exactly (2,599,774 words, 174,550 bigrams). It finds 0 broken pointers in both new files. Then the user tested on the phone.

## Rebuild

```sh
scripts/build_all.sh            # downloads sources into ./work, builds both dicts, verifies them
CAPPED_EXTRA=200000 scripts/build_all.sh   # change how many extra forms go into the <16 MiB build
```

## Install

- **Stock FUTO or HeliBoard:** import `main_pl_merged_v2.dict`.
- **Large dictionary:** install the APK, enable "FUTO Keyboard Unstable", add Polish, and import `main_pl_large_v203.dict`. Import it only into the Unstable keyboard, because stock FUTO refuses format 203.

## License

This project's scripts, documentation and dictionaries are licensed under **GPL-3.0** (see `LICENSE`).
Some parts keep their own licenses: the FUTO fork and APK use the FUTO Source First License
(non-commercial), the encoder uses Apache-2.0, and the source data is BSD-2-Clause / CC BY 4.0.
See `LICENSES.md` and `CREDITS.md`.
