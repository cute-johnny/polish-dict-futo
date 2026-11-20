# AGENT.md: notes for the next agent or developer

Read `README.md` first for the overview. This file covers what you need to change things safely:
facts, formats, pitfalls and what's left to do. Last updated 2026-11-20. Status: **working on the
user's phone.**

## Goal

A better Polish dictionary for **FUTO Keyboard** on Android: typing and swipe suggestions with full
Polish inflection. Two deliverables:
1. `dist/main_pl_merged_v2.dict`: works in stock FUTO and HeliBoard (format 202, under 16 MiB).
2. `dist/main_pl_large_v203.dict` plus the FUTO fork: lifts the 16 MiB limit (format 203).

## Working with this user

- **Clone shallowly:** `git clone --depth 1 --filter=blob:none --sparse …`, then
  `git sparse-checkout set <dirs>`. A full or deep clone of FUTO (682 MB) takes hours on their
  connection. A blobless sparse clone took 7 seconds.
- **Build the APK in GitHub Actions**, not locally. There's no Android SDK on this machine. A build
  takes about 8.5 minutes.
- **Don't open pull requests or issues upstream at FUTO for them.** FUTO rejects AI-generated PRs
  and asks for issues in the reporter's own words.
- **Keep their email private.** The fork uses a repo-local git identity: name `cute-johnny`, email
  GitHub noreply `<id>+cute-johnny@users.noreply.github.com`. Never use their real email.
- **Keep output short.** Redirect big logs to files and `tail`/`grep` them. See the global
  `~/.claude/CLAUDE.md`.
- **Phone:** Xiaomi `mondrian` (23013PC75G). Get the serial with `adb devices`. It disconnects sometimes, so use
  `adb wait-for-device`. Installed packages: `org.futo.inputmethod.latin` (stock) and
  `org.futo.inputmethod.latin.unstable` (the fork).
- **Permissions:** the auto-mode permission classifier blocked running
  `java -cp <patched classes>:dicttool_aosp.jar …` ("Undermining Oversight"). The user ran it with `!`.
  If you need it, ask the user to run it or to add a permission rule. Don't work around the block.

## Data sources

| Source | Size | Notes |
|---|---|---|
| polimorfologik 2.1, 2016 (github.com/morfologik/polimorfologik, release `2.1`) | 4,668,625 unique forms, 315,689 lemmas | Text format `lemma;form;tags` (semicolons; the form is **field 2**). No frequencies. About 275k capitalized entries (names). Missing newer words (selfie, koronawirus, …). |
| HeliBoard `main_pl__experimental.combined` (codeberg Helium314/aosp-dictionaries, `wordlists/`) | 2,599,774 words, 174,550 bigrams | Frequencies from the Leipzig corpora. **About 2.13M entries have f=15**, the floor: generated inflected forms. Has 124 entries flagged `possibly_offensive`. |
| Overlap | 2.31M shared, 2.36M polimorfologik-only, 0.29M HeliBoard-only | |

## The `.combined` text format (input to dicttool)

```
dictionary=main:pl,locale=pl,description=…,date=<unix>,version=<n>
 word=jest,f=192            # one leading space; f = 0..255
  bigram=przez,f=2          # two leading spaces; belongs to the word above
 word=xyz,f=10,possibly_offensive=true
```

## The binary `.dict` format (v202), and why 16 MiB is the limit

- Header: magic `9B C1 3A FE`, version (2 bytes, big-endian), options (2), header size (4), then
  key/value pairs separated by `0x1F`. dicttool sorts the keys alphabetically, so `date` comes first.
  FUTO's importer (`ImportResourceActivity.kt`, `parseDictionaryMetadataKV`) scans for
  `date\x1F` and reads pairs until it reaches `version`. It takes `locale` and `description` from
  these pairs, so they must come after `date`.
- Body: a Patricia trie of "PtNode arrays". Node flags: `0xC0` = children pointer size
  (00 none, 01 = 1 byte, 10 = 2 bytes, 11 = 3 bytes), `0x20` multiple chars, `0x10` terminal (one
  frequency byte follows), `0x08` shortcuts, `0x04` bigrams, `0x02` not-a-word, `0x01` offensive.
- Characters: a byte ≥ 0x20 is one character. A byte < 0x20 starts a 3-byte code point. `0x1F` ends
  a multi-character run. These dictionaries have no code point table.
- Children pointer: **unsigned, relative to the pointer's own position**, at most 3 bytes.
  Bigram pointer: flag byte (`0x80` has-next, `0x40` negative, `0x30` size, `0x0F` probability),
  then the offset, relative to the position just after the flag byte.
- **So any pointer that has to reach more than 2^24 − 1 bytes away breaks.** The encoder lays the
  trie out depth-first, so in a file over 16 MiB root-level pointers overflow. Stock dicttool
  doesn't check this; it silently keeps only the low 24 bits. Result: garbage suggestions
  (`docs/bug-…png`) and crashes during swipe typing.

## Format 203 (this project's extension)

- Exactly the same as v202, except that the "11" (3-byte) pointer size means **4 bytes**, for both
  children and bigram pointers.
- Writer: `encoder/src/.../BinaryDictEncoderUtils.java`, enabled with the system property
  `-Ddicttool.large=true`. It writes version 203 in the header but keeps formatOptions at 202
  internally, so the jar's version checks pass. In normal mode it **throws** instead of writing a
  corrupt file over 16 MiB.
- Reader: the FUTO fork, commit `04659de`, 14 files in `native/jni/src/dictionary/`:
  - `utils/format_utils.{h,cpp}`: `VERSION_203_LARGE_ADDRESSES = 203`.
  - `header/header_policy.h`, `header/header_read_write_utils.cpp`: accept 203.
  - `structure/dictionary_structure_with_buffer_policy_factory.cpp`: 203 →
    `PatriciaTriePolicy(buf, true)`.
  - `structure/v2/patricia_trie_policy.{h,cpp}`: member `mLargeAddresses` (declared **before**
    `mHeaderPolicy`, because of the order members are initialized in). It's passed to every
    `readChildrenPositionAndAdvancePosition` / `readPtNodeInfo` call.
  - `structure/v2/ver2_patricia_trie_node_reader.{h,cpp}`, `structure/v2/bigram/bigram_list_policy.h`:
    pass the flag through.
  - `structure/pt_common/patricia_trie_reading_utils.{h,cpp}`,
    `structure/pt_common/bigram/bigram_list_read_write_utils.{h,cpp}`: a `largeAddresses`
    parameter (default `false`). When it's true, the 3-byte case uses `readUint32AndAdvancePosition`.
  - v4 dictionaries (`DynamicPtReadingUtils`) are untouched.
- Stock FUTO's import screen accepts the file, because it only checks the magic number. The native
  loader then rejects version 203. So never import a 203 dictionary into stock FUTO.

## Encoder tooling

- `dicttool_aosp.jar` (HeliBoard copy) is a compiled AOSP build from 2017 with no source code. It
  **can't read** `.dict` files on a normal PC, because that needs the native
  `libjni_latinime-aosp-dicttool-host`. Use `scripts/check_dict.py` to inspect dictionaries.
- The patched classes come from AOSP LatinIME **master**: `tests/src/.../BinaryDictEncoderUtils.java`
  and `tests/src/.../Ver2DictEncoder.java`. The oreo/nougat branches don't have `Ver2DictEncoder` in
  that path. **Don't recompile `FormatSpec.java`**: it doesn't compile against the jar
  (`DecoderSpecificConstants` is missing), and its constants are inlined into compiled code anyway.
- Command (the classpath order matters, because the patched classes must come first):
  `java -Xmx6g [-Ddicttool.large=true] -cp cls:dicttool_aosp.jar com.android.inputmethod.latin.dicttool.Dicttool makedict -s in.combined -d out.dict`
- Expected log noise: thousands of lines like "Unigram freq is superior to bigram freq". They're harmless.
- Build time: about 2 minutes for 5M words. Peak RAM is a few GB.

## Verification

- `python3 -I scripts/check_dict.py file.dict` prints the version, word count, bigram count and
  broken-pointer counts. Expected results:
  - HeliBoard original: `version=202 words=2599774 bigrams=174550 bad…=0`. This is the control that
    shows the checker reads files correctly.
  - `main_pl_large_v203.dict`: `version=203 words=4957523 bigrams=174550 bad…=0`.
- The 16 MiB check is `stat -c %s` < 16777216. `main_pl_merged_v2.dict` is 16,190,914 bytes.
- On the device: import the dictionary, then swipe and type. Watch for crashes with
  `adb logcat -b crash -d | tail -50`.

## Fork and CI

- Repo: `github.com/cute-johnny/android-keyboard`, branch `large-dictionaries`. Local copy:
  `futo-keyboard/`, a blobless sparse clone. Add paths with `git sparse-checkout add <dir>`; new
  files outside the sparse set won't stage until you do.
- Workflow: `.github/workflows/build-apk.yml`. It runs on push to the branch or by manual dispatch.
  Steps: shallow checkout, then `git submodule update --init --recursive --depth 1` (the submodules
  are on gitlab.futo.org and huggingface, all public, and need git-lfs), JDK 17, NDK
  `28.2.13676358`, CMake 3.22.1, `./gradlew assembleUnstableRelease`, then upload the artifact.
  Without `keystore.properties` the release is signed with FUTO's public debug key
  (`java/shared.keystore`).
- Download the APK: `gh run download <run-id> -R cute-johnny/android-keyboard -D <dir>`. Install:
  `adb install -r <apk>`.
- **To update from upstream FUTO:**
  `git fetch --depth 1 https://github.com/futo-org/android-keyboard master`, then rebase or
  cherry-pick the commits in `futo-patch/`. Conflicts are most likely in
  `patricia_trie_policy.*`.
- License: FUTO Source First 1.1, **non-commercial**. Keep the "Modified version" notice at the top
  of the fork's README.

## Next step: automatic GitHub Releases (not done yet)

The workflow currently only uploads a **run artifact**. It isn't public, requires being logged in,
and expires after 90 days. Planned change to `.github/workflows/build-apk.yml` in the fork:

- Also trigger on tags: `on: push: tags: ['v*']`.
- On a tag build, after the APK step, create a GitHub Release, e.g. with `softprops/action-gh-release`
  or `gh release create "$GITHUB_REF_NAME" …`. Add `permissions: contents: write` to the job.
- Attach to the release: the APK, `main_pl_merged_v2.dict`, `main_pl_large_v203.dict`, `CREDITS.md`,
  `LICENSES.md` and `third-party-licenses/`. The licenses require shipping the credits and license
  texts. Under GPL-3.0, the dictionary source must also be provided: an xz-compressed `.combined`
  file, or a pointer to `scripts/build_all.sh`.
- The dictionaries aren't in the fork repo. Either commit them to a separate branch or folder (both
  files are under GitHub's 100 MB limit), or upload them from this machine:
  `gh release upload <tag> dist/*.dict -R cute-johnny/android-keyboard`.
- The release notes must say: unofficial, non-commercial, modified FUTO fork, not affiliated with
  FUTO; import the v203 dictionary only into "FUTO Keyboard Unstable".
- **Ask the user before pushing a tag or publishing.** A release makes the files publicly
  downloadable.

## Ideas for improvement (not done)

1. **Better ranking for polimorfologik-only words.** They all have f=10 now. You could give them a
   frequency derived from their base word, e.g. `max(1, 15 − k)` scaled by the base word's frequency.
2. **Fill the gaps in modern vocabulary:** koronawirus, emotka, scrollować and similar words are in
   neither source. Possible sources: wordfreq (Polish), OpenSubtitles FrequencyWords (`pl_50k`),
   NKJP frequency lists. Check their licenses first.
3. **Remove noise:** `possibly_offensive` handling, rare proper nouns (about 275k capitalized
   polimorfologik entries), and forms longer than 20 characters (about 82k).
4. **Bigrams are only HeliBoard's 174k.** A Polish bigram list would improve next-word prediction.
5. **Package a release:** a GitHub repo or Release holding the dictionaries, `CREDITS.md`,
   `LICENSES.md` and an xz-compressed `.combined` source. GitHub's per-file limit is 100 MB.
6. **Optional:** a FUTO import-time check that warns when a v202 file is over 16 MiB, which would
   help stock users who hit the old bug.
7. **Swipe performance with 5M words.** It works, but nobody has measured latency or memory. Use
   `adb shell dumpsys meminfo org.futo.inputmethod.latin.unstable`.

## Pitfalls already hit

- Wrong field: polimorfologik's **first** field is the lemma. The first count mixed them up.
- `/usr/bin/time` isn't installed; use the shell builtin `time`. `xxd` isn't installed; use `od`.
- Codeberg and googlesource downloads are fast. **github.com git clone is very slow** (about
  120 KB/s) on this connection; GitHub release and artifact downloads are fine.
- AOSP googlesource raw file: `https://android.googlesource.com/platform/packages/inputmethods/LatinIME/+/refs/heads/master/<path>?format=TEXT` (base64-encoded).
