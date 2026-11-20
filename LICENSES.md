# Licensing

This project's own work (scripts, documentation and the compiled dictionaries) is licensed under the
**GNU General Public License v3.0**. The full text is in `LICENSE`. The project also contains or uses
parts with **different licenses**, and those keep their own terms. This file explains which license applies
to what. It is a summary, not legal advice. The original license texts are in `third-party-licenses/`
or linked below.

| Part | License | Copyright holder | Obligations when you redistribute |
|---|---|---|---|
| polimorfologik 2.1 data (merged into both dictionaries) | **BSD-2-Clause** (`third-party-licenses/polimorfologik/LICENSE.txt`, Polish text in `LICENSE.Polish.txt`) | © 2016 Marcin Miłkowski | Keep the copyright notice, conditions and disclaimer. |
| HeliBoard `main_pl__experimental` word list (merged into both dictionaries) | **CC BY 4.0** for the source lists, per HeliBoard's README and `third-party-licenses/heliboard-wordlist/main_pl__experimental.source`. The HeliBoard repository as a whole is **GPL-3.0**. | Leipzig Corpora Collection; Helium314 and contributors | Credit the source, link the license, and say that the data was changed (merged and re-weighted). |
| `dicttool_aosp.jar` (build tool; downloaded at build time, not included) | **Apache-2.0** (AOSP LatinIME, via remi0s/aosp-dictionary-tools) | The Android Open Source Project | Not redistributed here. |
| `encoder/` (2 patched AOSP Java classes plus a diff) | **Apache-2.0** | The Android Open Source Project; modifications by this project | Keep the Apache-2.0 header. The files are marked as modified (large-address mode). |
| `futo-keyboard/`, `futo-patch/`, the APK in `dist/apk/` | **FUTO Source First License 1.1** (`futo-keyboard/LICENSE.md`) | © FUTO Holdings, Inc.; modifications by this project | **Non-commercial only.** Distribute free of charge. Keep FUTO's notices and license text. Mark the copy as modified (done in the fork's README). Don't remove the payment features. Don't use FUTO's trademarks as your own name. |
| `dist/*.dict` (the compiled dictionaries) | **GPL-3.0** (`LICENSE`). They combine BSD-2-Clause and CC BY 4.0 data; both are compatible with GPL-3.0, and this also covers HeliBoard's GPL-3.0 repository. | the repository owner, plus the data authors above | Ship this file, `CREDITS.md` and `third-party-licenses/` with them. Under GPL-3.0, also provide the source: the `.combined` word list, or `scripts/build_all.sh`, which recreates it. |
| `scripts/`, the documentation (`README.md`, `AGENT.md`, `CREDITS.md`, `LICENSES.md`) | **GPL-3.0** (`LICENSE`) | the repository owner | Keep the license and notices. Provide the source when you distribute. |

## Compatibility notes

- BSD-2-Clause data can go into a GPL-3.0 work. CC BY 4.0 → GPL-3.0 is an approved one-way
  compatibility (Creative Commons, 2015). So a GPL-3.0 release of the dictionaries is consistent.
- Don't put the dictionaries **inside** the FUTO fork and present them as FUTO-licensed. FUTO's CLA
  can only cover your own work, not third-party data. Keep them as separate files that users import.
- FUTO doesn't accept AI-generated pull requests (see their README), so this work isn't offered upstream.
- On GitHub, files must be under 100 MB. The 28.6 MB dictionary is fine. A `.combined` word list
  (about 128 MB) has to be compressed (xz) or attached to a GitHub Release.
