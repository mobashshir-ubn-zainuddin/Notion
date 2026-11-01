"""
Patch Notion.exe (copy of AutoHotkey64.exe):
  - Replace embedded icon with NotionIcon.ico
  - Update FileDescription / ProductName / CompanyName in version info
Uses only the Windows built-in UpdateResource API (no external tools).
"""
import ctypes, struct, os, sys, pathlib

k32 = ctypes.WinDLL('kernel32', use_last_error=True)
k32.BeginUpdateResourceW.restype  = ctypes.c_void_p
k32.BeginUpdateResourceW.argtypes = [ctypes.c_wchar_p, ctypes.c_bool]
k32.UpdateResourceW.restype  = ctypes.c_bool
k32.UpdateResourceW.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong,
                                 ctypes.c_ushort, ctypes.c_void_p, ctypes.c_ulong]
k32.EndUpdateResourceW.restype  = ctypes.c_bool
k32.EndUpdateResourceW.argtypes = [ctypes.c_void_p, ctypes.c_bool]
k32.LoadLibraryExW.restype  = ctypes.c_void_p
k32.LoadLibraryExW.argtypes = [ctypes.c_wchar_p, ctypes.c_void_p, ctypes.c_ulong]
k32.FreeLibrary.argtypes   = [ctypes.c_void_p]
k32.FindResourceW.restype  = ctypes.c_void_p
k32.FindResourceW.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong]
k32.SizeofResource.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
k32.LoadResource.restype   = ctypes.c_void_p
k32.LoadResource.argtypes  = [ctypes.c_void_p, ctypes.c_void_p]
k32.LockResource.restype   = ctypes.c_void_p
k32.LockResource.argtypes  = [ctypes.c_void_p]

ROOT = pathlib.Path(__file__).parent.parent
EXE  = str(ROOT / "Notion.exe")
ICO  = str(ROOT / "NotionIcon.ico")

RT_ICON = 3; RT_GROUP_ICON = 14; RT_VERSION = 16
LANG_EN_US = 0x0409


def read_ico(path):
    with open(path, "rb") as f:
        data = f.read()
    _, _, count = struct.unpack_from("<HHH", data, 0)
    images = []
    for i in range(count):
        off = 6 + i * 16
        w, h, cc, res, planes, bc, sz, img_off = struct.unpack_from("<BBBBHHII", data, off)
        images.append((w or 256, h or 256, planes or 1, bc or 32, data[img_off:img_off+sz]))
    return images


def make_grpicondir(images, base_id):
    count = len(images)
    hdr = struct.pack("<HHH", 0, 1, count)
    entries = b""
    for idx, (w, h, planes, bc, img_data) in enumerate(images):
        entries += struct.pack("<BBBBHHIH", w & 0xFF, h & 0xFF, 0, 0,
                               planes, bc, len(img_data), base_id + idx)
    return hdr + entries


def get_version_blob(exe):
    hmod = k32.LoadLibraryExW(exe, None, 0x00000002)
    if not hmod:
        return None
    hrsrc = k32.FindResourceW(hmod, 1, RT_VERSION)
    if not hrsrc:
        k32.FreeLibrary(hmod)
        return None
    size = k32.SizeofResource(hmod, hrsrc)
    hdata = k32.LoadResource(hmod, hrsrc)
    ptr = k32.LockResource(hdata)
    raw = (ctypes.c_char * size).from_address(ptr)[:]
    k32.FreeLibrary(hmod)
    return bytearray(raw)


def patch_utf16(blob, old, new):
    old_e = old.encode("utf-16-le")
    new_e = new.encode("utf-16-le")
    assert len(new_e) <= len(old_e), f"Replacement too long: {new!r} > {old!r}"
    new_padded = new_e + b"\x00" * (len(old_e) - len(new_e))
    idx = count = 0
    while True:
        pos = bytes(blob).find(old_e, idx)
        if pos == -1:
            break
        blob[pos:pos+len(old_e)] = new_padded
        idx = pos + len(old_e)
        count += 1
    return count


print(f"[1/3] Reading ICO:  {ICO}")
images = read_ico(ICO)
print(f"      {len(images)} sizes: " + ", ".join(f"{w}x{h}" for w,h,*_ in images))

print(f"[2/3] Patching version info in: {EXE}")
ver = get_version_blob(EXE)
if ver:
    n  = patch_utf16(ver, "AutoHotkey 64-bit",        "Notion")
    n += patch_utf16(ver, "AutoHotkey Foundation LLC", "Notion Labs, Inc.")
    n += patch_utf16(ver, "AutoHotkey",                "Notion")
    print(f"      {n} replacements made")
else:
    print("      (no version resource — skipping)")

print(f"[3/3] Updating resources in exe…")
hupd = k32.BeginUpdateResourceW(EXE, False)
if not hupd:
    print(f"BeginUpdateResource FAILED: {ctypes.get_last_error()}"); sys.exit(1)

BASE_ID = 1
for idx, (w, h, planes, bc, img_data) in enumerate(images):
    buf = (ctypes.c_char * len(img_data)).from_buffer_copy(img_data)
    ok = k32.UpdateResourceW(hupd, RT_ICON, BASE_ID + idx, LANG_EN_US, buf, len(img_data))
    print(f"  RT_ICON id={BASE_ID+idx} ({w}x{h}): {'ok' if ok else f'FAIL {ctypes.get_last_error()}'}")

grp = make_grpicondir(images, BASE_ID)
buf = (ctypes.c_char * len(grp)).from_buffer_copy(grp)
ok  = k32.UpdateResourceW(hupd, RT_GROUP_ICON, 1, LANG_EN_US, buf, len(grp))
print(f"  RT_GROUP_ICON: {'ok' if ok else f'FAIL {ctypes.get_last_error()}'}")

if ver:
    buf = (ctypes.c_char * len(ver)).from_buffer_copy(ver)
    ok  = k32.UpdateResourceW(hupd, RT_VERSION, 1, LANG_EN_US, buf, len(ver))
    print(f"  RT_VERSION: {'ok' if ok else f'FAIL {ctypes.get_last_error()}'}")

if k32.EndUpdateResourceW(hupd, False):
    print("Done — Notion.exe patched successfully.")
else:
    print(f"EndUpdateResource FAILED: {ctypes.get_last_error()}"); sys.exit(1)
