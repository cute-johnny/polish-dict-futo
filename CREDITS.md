# Credits and thanks

This project mostly combines other people's work. Thanks to everyone below.

## Word data

- **Morfologik / polimorfologik**: Marcin Miłkowski, the Morfologik project
  (https://github.com/morfologik/polimorfologik). Used: Polish morphological dictionary, version 2.1.
  - **sjp.pl / kurnik.pl dictionary** and the original **Polish ispell** dictionary by
    Mirosław Prywata, Piotr Gackiewicz, Włodzimierz Macewicz, Łukasz Szałkiewicz and Marek Futrega.
  - **PoliMorf / SGJP** (Słownik gramatyczny języka polskiego) by Zygmunt Saloni,
    Włodzimierz Gruszczyński, Marcin Woliński and Robert Wołosz.
  - The PoliMorf version was developed in the **CESAR** project at the Linguistic Engineering Group,
    **IPI PAN** (Institute of Computer Science, Polish Academy of Sciences), with help from
    Jan Szejko and Adam Radziszewski.
- **HeliBoard dictionaries** by Helium314 and contributors
  (https://codeberg.org/Helium314/aosp-dictionaries). Used: the `main_pl__experimental` word list,
  which has the frequencies and bigrams, and the `dicttool_aosp.jar` build tool.
- **Leipzig Corpora Collection / Wortschatz**, Universität Leipzig
  (https://wortschatz.uni-leipzig.de/en/download/). This is the source of the Polish frequency
  lists in the HeliBoard word list.

## Software

- **FUTO Keyboard** by FUTO Holdings, Inc. (https://keyboard.futo.tech/,
  https://github.com/futo-org/android-keyboard). The keyboard this project patches.
- **AOSP LatinIME** by The Android Open Source Project. The dictionary format, the native
  dictionary engine, and the encoder classes this project patches.
- **aosp-dictionary-tools** by remi0s (https://github.com/remi0s/aosp-dictionary-tools). The
  packaged `dicttool_aosp.jar` that HeliBoard redistributes.

## This project

Assembled by the repository owner with Claude (Anthropic) as an AI coding assistant.
