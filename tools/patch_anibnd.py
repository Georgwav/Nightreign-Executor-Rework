"""Builds mod/chr/c0000.anibnd.dcx: the vanilla c0000.anibnd.dcx with two timeline changes.

1. The Cursed Sword's deflect flinch (animation a000_010005, event W_AddDamageGuardStartDemonSword)
   plays the full Cursed Sword deflect sparks on the guarding weapon and its sound, for the
   rework's passive deflects.
2. The Cursed Sword stance layer (a907_579000 / a907_579001, which the rework turns on during the
   skill's dash slash) no longer switches the grip to "right weapon two-handed", so the grip from
   before the skill stays (the event becomes a duplicate of the layer's Add SpEffect 707060). The
   layer still sheathes the weapons (event 712, for every grip) and attaches the Cursed Sword to
   the hand (event 719).

Changes to a000_010005 (in a00.tae):
- sound: c809001 (the light deflect sound) -> c809000 (the full deflect sound, as in a000_019480)
- the old sparks (462801 on the Cursed Sword, dummy poly 5110) only play while the stance is on
  (state info 609), i.e. for a deflect during the dash slash, when the Cursed Sword is in hand
- new: sparks 462800 (as in a000_019480) where the blocking weapon takes the hit, picked by a
  marker SpEffect the script applies with the deflect window: the right weapon's blade (dummy
  poly 10300) while 707008 is on (state info 2195), the left weapon's blade (11300) while 707009
  is on (2196), the left hand (21) while 707012 is on (2197) and the right hand (20) while 707013
  is on (2198); the hands are for short weapons (daggers, fists, claws; two-handed claws and
  fists block with the left hand). Dummy polys 20 / 21 are the hand points the stance layer
  attaches the Cursed Sword to

Usage: python3 tools/patch_anibnd.py <vanilla c0000.anibnd.dcx> <ooz_dcx decompressor> <out.dcx>
The decompressor is only needed to read the vanilla file (Oodle Kraken). The output is written as
a DCX whose Kraken blocks are stored uncompressed, which needs no compressor.
"""
import struct
import subprocess
import sys
import tempfile

ANIM_ID = 10005
DEFLECT_ANIM_ID = 19480  # vanilla full-body Cursed Sword deflect, source of the sound event
STATE_STANCE = 609
# (dummy poly, state info): right weapon's blade, left weapon's blade, left hand, right hand
MARKERS = [(10300, 2195), (11300, 2196), (21, 2197), (20, 2198)]
LAYER_ANIMS = [579000, 579001]  # in a907.tae
EVENT_SET_WEAPON_STYLE = 32
EVENT_ADD_SPEFFECT = 67
STANCE_SPEFFECT = 707060
FFX_FULL = 462800


def i32(d, o): return struct.unpack_from('<i', d, o)[0]
def i64(d, o): return struct.unpack_from('<q', d, o)[0]


def anim_header(tae, anim_id):
    count, table = i32(tae, 0x54), i64(tae, 0x58)
    for i in range(count):
        if i64(tae, table + i * 16) == anim_id:
            return i64(tae, table + i * 16 + 8)
    raise KeyError(anim_id)


def events(tae, ahdr):
    ev_off, ev_count = i64(tae, ahdr), i32(tae, ahdr + 0x20)
    out = []
    for j in range(ev_count):
        hdr = ev_off + j * 0x18
        data = i64(tae, hdr + 16)
        out.append(dict(hdr=hdr, data=data, type=i32(tae, data), params=i64(tae, data + 8)))
    return out


def patch_tae(tae):
    tae = bytearray(tae)
    ahdr = anim_header(tae, ANIM_ID)
    evs = events(tae, ahdr)
    by_type = {e['type']: e for e in evs}
    assert sorted(by_type) == [67, 96, 129], 'unexpected events in a000_010005'
    snd, ffx = by_type[129], by_type[96]
    assert i32(tae, snd['params'] + 4) == 809001 and i32(tae, ffx['params']) == 462801

    # sound: copy the full deflect's sound parameters (32 bytes) over the light one
    full = [e for e in events(tae, anim_header(tae, DEFLECT_ANIM_ID))
            if e['type'] == 129 and i32(tae, e['params'] + 4) == 809000][0]
    tae[snd['params']:snd['params'] + 32] = tae[full['params']:full['params'] + 32]

    # old sparks: only during the stance (dash slash deflect)
    struct.pack_into('<h', tae, ffx['params'] + 16, STATE_STANCE)

    # append: new event header array, two new spark events, new index array for the FFX group
    def align(buf):
        buf.extend(b'\0' * (-len(buf) % 16))
    align(tae)
    new_hdrs = len(tae)
    n_old = len(evs)
    tae.extend(b'\0' * (0x18 * (n_old + len(MARKERS))))
    align(tae)
    for j, e in enumerate(evs):
        tae[new_hdrs + j * 0x18:new_hdrs + j * 0x18 + 0x18] = tae[e['hdr']:e['hdr'] + 0x18]
    start_ptr, end_ptr = i64(tae, ffx['hdr']), i64(tae, ffx['hdr'] + 8)
    ffx_params = bytes(tae[ffx['params']:ffx['params'] + 24])
    for k, (dmy, state) in enumerate(MARKERS):
        data = len(tae)
        params = bytearray(ffx_params)
        struct.pack_into('<ii', params, 0, FFX_FULL, dmy)
        struct.pack_into('<h', params, 16, state)
        tae.extend(struct.pack('<iiq', 96, 0, data + 16) + params)
        align(tae)
        hdr = new_hdrs + (n_old + k) * 0x18
        struct.pack_into('<qqq', tae, hdr, start_ptr, end_ptr, data)

    # event groups list their events as 4-byte event header offsets (padded to 16 bytes): move
    # them to the new header array; the FFX group gets the two new events as well
    old_to_new = {e['hdr']: new_hdrs + j * 0x18 for j, e in enumerate(evs)}
    grp_off, grp_count = i64(tae, ahdr + 8), i32(tae, ahdr + 0x24)
    for g in range(grp_count):
        grp = grp_off + g * 0x20
        count, idx_off, gdata = i64(tae, grp), i64(tae, grp + 8), i64(tae, grp + 16)
        for n in range(count):
            old = struct.unpack_from('<I', tae, idx_off + n * 4)[0]
            struct.pack_into('<I', tae, idx_off + n * 4, old_to_new[old])
        if i64(tae, gdata) == 96:
            assert count == 1
            new_idx = len(tae)
            tae.extend(struct.pack('<I', old_to_new[ffx['hdr']]))
            for k in range(len(MARKERS)):
                tae.extend(struct.pack('<I', new_hdrs + (n_old + k) * 0x18))
            align(tae)
            struct.pack_into('<qq', tae, grp, 1 + len(MARKERS), new_idx)

    struct.pack_into('<q', tae, ahdr, new_hdrs)
    struct.pack_into('<i', tae, ahdr + 0x20, n_old + len(MARKERS))
    struct.pack_into('<i', tae, 0x0C, len(tae))
    return bytes(tae)


def patch_layer_tae(tae):
    """Disables the stance layer's Set Weapon Style event by turning it into an Add SpEffect of
    707060, which the layer already applies anyway (so the duplicate changes nothing). The event
    group that lists it gets the same type. Same size, changed in place."""
    tae = bytearray(tae)
    for anim_id in LAYER_ANIMS:
        ahdr = anim_header(tae, anim_id)
        evs = events(tae, ahdr)
        style = [e for e in evs if e['type'] == EVENT_SET_WEAPON_STYLE]
        assert len(style) == 1 and i32(tae, style[0]['params']) == 3, 'unexpected layer events'
        assert any(e['type'] == EVENT_ADD_SPEFFECT and i32(tae, e['params']) == STANCE_SPEFFECT for e in evs)
        e = style[0]
        struct.pack_into('<i', tae, e['data'], EVENT_ADD_SPEFFECT)
        struct.pack_into('<ii', tae, e['params'], STANCE_SPEFFECT, 0)
        grp_off, grp_count = i64(tae, ahdr + 8), i32(tae, ahdr + 0x24)
        found = 0
        for g in range(grp_count):
            grp = grp_off + g * 0x20
            count, idx_off, gdata = i64(tae, grp), i64(tae, grp + 8), i64(tae, grp + 16)
            listed = [struct.unpack_from('<I', tae, idx_off + n * 4)[0] for n in range(count)]
            if e['hdr'] in listed:
                assert count == 1 and i64(tae, gdata) == EVENT_SET_WEAPON_STYLE
                struct.pack_into('<q', tae, gdata, EVENT_ADD_SPEFFECT)
                found += 1
        assert found == 1, 'layer style event group not found'
    return bytes(tae)


def bnd4_entries(bnd):
    count, fhsize = i32(bnd, 0x0C), i64(bnd, 0x20)
    assert bnd[:4] == b'BND4' and fhsize == 0x24 and bnd[0x31] == 0x74
    out = []
    for i in range(count):
        p = 0x40 + i * fhsize
        size, off, name_off = i64(bnd, p + 8), struct.unpack_from('<I', bnd, p + 0x18)[0], struct.unpack_from('<I', bnd, p + 0x20)[0]
        end = name_off
        while bnd[end:end + 2] != b'\0\0':
            end += 2
        out.append(dict(hdr=p, size=size, off=off, name=bnd[name_off:end].decode('utf-16-le')))
    return out


def replace_in_bnd4(bnd, suffix, new_data):
    entries = bnd4_entries(bnd)
    target = [e for e in entries if e['name'].endswith(suffix)]
    assert len(target) == 1
    t = target[0]
    assert len(new_data) % 16 == 0 and t['size'] % 16 == 0
    delta = len(new_data) - t['size']
    head = bytearray(bnd[:t['off']])
    for e in entries:
        if e is t:
            struct.pack_into('<qq', head, e['hdr'] + 8, len(new_data), len(new_data))
        elif e['off'] > t['off']:
            struct.pack_into('<I', head, e['hdr'] + 0x18, e['off'] + delta)
    return bytes(head) + new_data + bnd[t['off'] + t['size']:]


def dcx_stored_kraken(template_dcx, data):
    hdr = bytearray(template_dcx[:0x4C])
    assert hdr[:4] == b'DCX\0' and hdr[0x28:0x2C] == b'KRAK'
    stream = bytearray()
    for pos in range(0, len(data), 0x40000):
        stream += b'\xCC\x06' + data[pos:pos + 0x40000]  # restart + uncompressed block, Kraken
    struct.pack_into('>II', hdr, 0x1C, len(data), len(stream))
    return bytes(hdr) + bytes(stream)


def main():
    src, ooz, out = sys.argv[1:4]
    vanilla = open(src, 'rb').read()
    with tempfile.NamedTemporaryFile() as tmp:
        subprocess.run([ooz, src, tmp.name], check=True, stdout=subprocess.DEVNULL)
        bnd = open(tmp.name, 'rb').read()
    def tae_file(data, name):
        entry = [e for e in bnd4_entries(data) if e['name'].endswith(name)][0]
        return data[entry['off']:entry['off'] + entry['size']]
    new_bnd = replace_in_bnd4(bnd, '\\a00.tae', patch_tae(tae_file(bnd, '\\a00.tae')))
    new_bnd = replace_in_bnd4(new_bnd, '\\a907.tae', patch_layer_tae(tae_file(new_bnd, '\\a907.tae')))
    open(out, 'wb').write(dcx_stored_kraken(vanilla, new_bnd))
    print('wrote', out, len(new_bnd), 'bytes unpacked')


if __name__ == '__main__':
    main()
