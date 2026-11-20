# SPDX-License-Identifier: GPL-3.0-only
# Walk an AOSP v202/v203 binary dictionary like the native reader; count words, validate pointers.
import sys, struct
data = open(sys.argv[1], 'rb').read()
ver = struct.unpack('>H', data[4:6])[0]; large = (ver == 203)
hsize = struct.unpack('>I', data[8:12])[0]
b = data[hsize:]; n = len(b)
def u(pos, k): return int.from_bytes(b[pos:pos+k], 'big'), pos + k
words = 0; nodes = 0; bigrams = 0; bad = 0; node_starts = set(); bigram_targets = []
samples = []
stack = [(0, '')]
while stack:
    apos, prefix = stack.pop()
    if not (0 <= apos < n): bad += 1; continue
    c, p = u(apos, 1)
    if c & 0x80: c2, p = u(p, 1); c = ((c & 0x7F) << 8) | c2
    for _ in range(c):
        node_starts.add(p); nodes += 1
        flags, p = u(p, 1)
        chars = []
        while True:
            fb = b[p]
            if fb < 0x20:
                if fb == 0x1F: p += 1; break
                cp, p = u(p, 3)
            else:
                cp = fb; p += 1
            chars.append(chr(cp))
            if not (flags & 0x20): break
        w = prefix + ''.join(chars)
        if flags & 0x10:
            _, p = u(p, 1); words += 1
            if words % 500000 == 1: samples.append(w)
        t = flags & 0xC0
        if t:
            base = p; size = {0x40: 1, 0x80: 2, 0xC0: 4 if large else 3}[t]
            off, p = u(p, size); stack.append((base + off, w))
        if flags & 0x08:
            s, _ = u(p, 2); p += s
        if flags & 0x04:
            while True:
                bf, p = u(p, 1); origin = p
                size = {0x10: 1, 0x20: 2, 0x30: 4 if large else 3}.get(bf & 0x30, 0)
                off, p = u(p, size)
                bigram_targets.append(origin - off if bf & 0x40 else origin + off); bigrams += 1
                if not (bf & 0x80): break
badb = sum(1 for t in bigram_targets if t not in node_starts)
print(f"version={ver} body={n} nodes={nodes} words={words} bigrams={bigrams} bad_child_ptrs={bad} bad_bigram_ptrs={badb}")
print("samples:", samples)
