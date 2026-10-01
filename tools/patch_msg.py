"""Builds mod/msg/engus/menu_dlc01.msgbnd.dcx: the vanilla English menu texts with the Executor's
passive, Character Skill and Ultimate Art texts from docs/TEXT.md.

The character select texts are in CL_MenuText.fmg (FMG 200). The Executor's entries end in 07;
those ending in 17 are the variants after the Executor's Remembrance (golden sword):
  411x07 skill name (x = 1: the sword's name), 412007 skill summary, 412107 skill details
  413007 Ultimate Art name, 414007 summary, 414107 details
  415007 passive name, 416007 summary, 416107 details
Summaries have at most 2 lines and details at most 3, of up to about 48 characters.

Each text is set by FMG id and entry id, and the vanilla text is checked first, so a game update
that moves or rewrites an entry stops the build instead of changing the wrong text. Other entries
stay byte-identical: a new text is appended to the end of its FMG and the entry points to it.

Usage: python3 tools/patch_msg.py <vanilla menu_dlc01.msgbnd.dcx> <ooz_dcx decompressor> <out.dcx>
The decompressor is only needed to read a Kraken-compressed file. A Kraken file is written as a
DCX whose Kraken blocks are stored uncompressed, which needs no compressor; a DFLT file is written
with zlib.
"""
import struct
import subprocess
import sys
import tempfile
import zlib

MENU_TEXT = 200

# (fmg id, entry id): (vanilla text, new text)
TEXTS = {
    # passive
    (MENU_TEXT, 415007): ('Tenacity', 'Deflection'),
    (MENU_TEXT, 415017): ('Tenacity', 'Deflection'),
    (MENU_TEXT, 416007): ('Receive boost after recovering\nfrom status ailments.',
                          "Guard in time with a foe's attack to\ndeflect it with almost any weapon."),
    (MENU_TEXT, 416107): ('Effect boosts attack and stamina recovery speed.',
                          'Deflect window by weapon: 100% swords, katanas,\n'
                          'daggers, fists, claws. 65% greatswords, axes,\n'
                          'hammers, polearms. 30% colossal weapons.'),
    # Character Skill
    (MENU_TEXT, 412007): ('Draw a cursed sword that\ncan deflect enemy attacks.',
                          'Draw the cursed sword and\ndash forward with a swift slash.'),
    (MENU_TEXT, 412017): ("Draw the Executor's golden sword that\ncan deflect enemy attacks.",
                          "Draw the Executor's golden sword and\ndash forward with a swift slash."),
    (MENU_TEXT, 412107): ('Repeated deflections reveal blade, enabling\n'
                          'powerful attacks with the living sword.\n'
                          'Cannot run while at ready with enchanted blade.',
                          'Deflect four attacks to imbue the blade with\n'
                          'holy light for 20 seconds. The next slash\n'
                          "unleashes the living sword's power."),
    (MENU_TEXT, 412117): ('Repeated deflections reveal blade, enabling\n'
                          'powerful attacks with the living sword. The blade\n'
                          'lost its voice, but is forever loyal to its master.',
                          'Deflect four attacks to imbue the blade with\n'
                          'holy light for 20 seconds. The blade lost its\n'
                          'voice, but is forever loyal to its master.'),
    # Ultimate Art
    (MENU_TEXT, 414107): ('Use unique attacks in beast form that\n'
                          'drain the Ultimate Art gauge. Activate again\n'
                          'to quickly undo transformation.',
                          'Use unique attacks in beast form that\n'
                          'drain the Ultimate Art gauge. The beast keeps\n'
                          'your HP ratio; you return with your prior HP.'),
}


def i32(d, o): return struct.unpack_from('<i', d, o)[0]
def i64(d, o): return struct.unpack_from('<q', d, o)[0]


def fmg_offsets(fmg):
    """Maps entry id -> position of its string offset (FMG version 2, 64-bit offsets)."""
    assert fmg[0] == 0 and fmg[1] == 0 and fmg[2] == 2, 'not a little-endian FMG version 2'
    groups, table = i32(fmg, 0x0C), i64(fmg, 0x18)
    out = {}
    for g in range(groups):
        first_index, first_id, last_id = struct.unpack_from('<iii', fmg, 0x28 + g * 0x10)
        for n in range(last_id - first_id + 1):
            out[first_id + n] = table + (first_index + n) * 8
    return out


def fmg_text(fmg, pos):
    off = i64(fmg, pos)
    if off == 0:
        return None
    end = off
    while fmg[end:end + 2] != b'\0\0':
        end += 2
    return fmg[off:end].decode('utf-16-le')


def fmg_set_texts(fmg, texts):
    """texts: entry id -> (vanilla text, new text)."""
    fmg = bytearray(fmg)
    offsets = fmg_offsets(fmg)
    for entry, (old, new) in texts.items():
        pos = offsets[entry]
        assert fmg_text(fmg, pos) == old, f'entry {entry}: vanilla text differs: {fmg_text(fmg, pos)!r}'
        fmg.extend(b'\0' * (len(fmg) % 2))
        struct.pack_into('<q', fmg, pos, len(fmg))
        fmg.extend(new.encode('utf-16-le') + b'\0\0')
    struct.pack_into('<i', fmg, 0x04, len(fmg))
    return bytes(fmg)


def bnd4_entries(bnd):
    count, fhsize = i32(bnd, 0x0C), i64(bnd, 0x20)
    assert bnd[:4] == b'BND4' and fhsize == 0x24 and bnd[0x30] == 1 and bnd[0x31] == 0x74, \
        'unexpected BND4 layout'
    out = []
    for i in range(count):
        p = 0x40 + i * fhsize
        size, off = i64(bnd, p + 8), struct.unpack_from('<I', bnd, p + 0x18)[0]
        fid, name_off = i32(bnd, p + 0x1C), struct.unpack_from('<I', bnd, p + 0x20)[0]
        end = name_off
        while bnd[end:end + 2] != b'\0\0':
            end += 2
        out.append(dict(hdr=p, size=size, off=off, id=fid, name=bnd[name_off:end].decode('utf-16-le')))
    return out


def bnd4_rebuild(bnd, new_files):
    """new_files: file id -> new data. Lays all files out again in their original order, each
    starting on a 16-byte boundary."""
    entries = sorted(bnd4_entries(bnd), key=lambda e: e['off'])
    start = entries[0]['off']
    head = bytearray(bnd[:start])
    body = bytearray()
    for e in entries:
        data = new_files.get(e['id'], bnd[e['off']:e['off'] + e['size']])
        body.extend(b'\0' * (-(start + len(body)) % 16))
        struct.pack_into('<qqI', head, e['hdr'] + 8, len(data), len(data), start + len(body))
        body.extend(data)
    return bytes(head) + bytes(body)


def dcx_read(path, ooz):
    dcx = open(path, 'rb').read()
    assert dcx[:4] == b'DCX\0'
    fmt = dcx[0x28:0x2C]
    if fmt == b'DFLT':
        return dcx, zlib.decompress(dcx[0x4C:])
    assert fmt == b'KRAK', f'unknown DCX compression {fmt!r}'
    with tempfile.NamedTemporaryFile() as tmp:
        subprocess.run([ooz, path, tmp.name], check=True, stdout=subprocess.DEVNULL)
        return dcx, open(tmp.name, 'rb').read()


def dcx_write(template_dcx, data):
    hdr = bytearray(template_dcx[:0x4C])
    if hdr[0x28:0x2C] == b'DFLT':
        stream = zlib.compress(data, 9)
    else:
        stream = bytearray()
        for pos in range(0, len(data), 0x40000):
            stream += b'\xCC\x06' + data[pos:pos + 0x40000]  # restart + uncompressed block, Kraken
    struct.pack_into('>II', hdr, 0x1C, len(data), len(stream))
    return bytes(hdr) + bytes(stream)


def main():
    src, ooz, out = sys.argv[1:4]
    template, bnd = dcx_read(src, ooz)
    entries = {e['id']: e for e in bnd4_entries(bnd)}
    by_fmg = {}
    for (fmg_id, entry), texts in TEXTS.items():
        by_fmg.setdefault(fmg_id, {})[entry] = texts
    new_files = {}
    for fmg_id, texts in by_fmg.items():
        e = entries[fmg_id]
        new_files[fmg_id] = fmg_set_texts(bnd[e['off']:e['off'] + e['size']], texts)
    open(out, 'wb').write(dcx_write(template, bnd4_rebuild(bnd, new_files)))
    print('wrote', out, 'changed', len(TEXTS), 'texts')


if __name__ == '__main__':
    main()
