# SPDX-License-Identifier: GPL-3.0-only
# rank polimorfologik-only forms by how common their lemma family is in the HeliBoard list
import sys, collections
words_tsv, pm_txt, out = sys.argv[1:4]
freq = {}
for line in open(words_tsv, encoding='utf-8'):
    w, f = line.rstrip('\n').split('\t'); freq[w] = int(f)
lemma_score = collections.Counter(); pairs = []
for line in open(pm_txt, encoding='utf-8'):
    p = line.split(';', 2)
    if len(p) < 2: continue
    lem, form = p[0], p[1]
    pairs.append((lem, form))
    f = freq.get(form, 0)
    if f > 15: lemma_score[lem] += f
best = {}
for lem, form in pairs:
    if form in freq or any(c in form for c in '0123456789. '): continue
    s = lemma_score.get(lem, 0)
    if s > best.get(form, 0): best[form] = s
ranked = sorted(best.items(), key=lambda x: -x[1])
with open(out, 'w', encoding='utf-8') as o:
    for w, s in ranked: o.write(f"{w}\t{s}\n")
print(len(ranked), sum(1 for _, s in ranked if s > 0))
