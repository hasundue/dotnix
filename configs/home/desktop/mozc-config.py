"""Patch fields of mozc's config1.db in place.

config1.db is not sqlite: it is a serialized `mozc.config.Config` protobuf (see
src/protocol/config.proto upstream), and mozc ships no way to import or export
one. This script rewrites only the fields named on the command line and copies
every other byte through unchanged, so settings made in the "Mozc Settings"
dialog survive. Nothing is written when the values already match.

Usage: mozc-config.py PATH FIELD=VALUE [FIELD=VALUE ...]
"""

import os
import sys

WANT = {}
for arg in sys.argv[2:]:
    key, _, value = arg.partition("=")
    WANT[int(key)] = int(value)


def read_varint(buf, i):
    shift = 0
    value = 0
    while True:
        byte = buf[i]
        i += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, i
        shift += 7


def encode_varint(value):
    out = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        out.append(byte | (0x80 if value else 0))
        if not value:
            return bytes(out)


path = sys.argv[1]
data = open(path, "rb").read()

pieces = []  # (field number, raw bytes, varint value or None)
i = 0
while i < len(data):
    start = i
    key, i = read_varint(data, i)
    field, wire = key >> 3, key & 7
    if wire == 0:
        value, i = read_varint(data, i)
        pieces.append((field, data[start:i], value))
    elif wire == 2:
        length, i = read_varint(data, i)
        i += length
        pieces.append((field, data[start:i], None))
    elif wire == 5:
        i += 4
        pieces.append((field, data[start:i], None))
    elif wire == 1:
        i += 8
        pieces.append((field, data[start:i], None))
    else:
        sys.exit(f"mozc-config: unexpected wire type {wire} for field {field}")

# Every field we set must be present exactly once, or the file needs a rewrite.
present = {field: value for field, _, value in pieces if field in WANT}
if present == WANT and sum(1 for f, _, _ in pieces if f in WANT) == len(WANT):
    sys.exit(0)

seen = set()
out = bytearray()
for field, raw, value in pieces:
    if field not in WANT:
        out += raw
    elif field not in seen:
        seen.add(field)
        out += encode_varint(field << 3) + encode_varint(WANT[field])
for field, value in WANT.items():
    if field not in seen:
        out += encode_varint(field << 3) + encode_varint(value)

# Write beside the original so a crash mid-write cannot truncate the database.
tmp = path + ".tmp"
with open(tmp, "wb") as f:
    f.write(bytes(out))
os.chmod(tmp, 0o600)
os.replace(tmp, path)
print(f"mozc-config: set {', '.join(f'{k}={v}' for k, v in sorted(WANT.items()))}")
