"""Shrink apple/Shared/Resources/TennisRacket.glb for the web emulator.

The app ships a 15 MB model: two 4096x4096 textures and a 2048 roughness map. The racket material uses only
the base-color and roughness textures, so the normal map is replaced with a 4x4 stub and the rest are resized.
Usage: python3 tools/optimize_racket_glb.py [in.glb] [out.glb]
"""
import io, json, struct, sys
from PIL import Image

src = sys.argv[1] if len(sys.argv) > 1 else "apple/Shared/Resources/TennisRacket.glb"
dst = sys.argv[2] if len(sys.argv) > 2 else "website/emulator/TennisRacket.glb"
data = open(src, "rb").read()
jlen = struct.unpack("<I", data[12:16])[0]
gltf = json.loads(data[20:20 + jlen])
bo = 20 + jlen
blen = struct.unpack("<I", data[bo:bo + 4])[0]
binary = data[bo + 8:bo + 8 + blen]

used = {t["source"] for m in gltf["materials"] for t in
        [m.get("pbrMetallicRoughness", {}).get("baseColorTexture"),
         m.get("pbrMetallicRoughness", {}).get("metallicRoughnessTexture"),
         m.get("normalTexture")] if t for t in [gltf["textures"][t["index"]]]}
# materials reference texture indices; map to image sources
used_tex = set()
for m in gltf["materials"]:
    pbr = m.get("pbrMetallicRoughness", {})
    for t in (pbr.get("baseColorTexture"), pbr.get("metallicRoughnessTexture"), m.get("normalTexture"),
              m.get("occlusionTexture"), m.get("emissiveTexture")):
        if t:
            used_tex.add(gltf["textures"][t["index"]]["source"])

replace = {}
for i, im in enumerate(gltf["images"]):
    bv = gltf["bufferViews"][im["bufferView"]]
    raw = binary[bv["byteOffset"]:bv["byteOffset"] + bv["byteLength"]]
    if i not in used_tex:
        out = io.BytesIO(); Image.new("RGB", (4, 4), (128, 128, 255)).save(out, "PNG")
        replace[im["bufferView"]] = (out.getvalue(), "image/png")
        continue
    img = Image.open(io.BytesIO(raw)).convert("RGB")
    size = 1024 if max(img.size) >= 4096 else 512
    img = img.resize((size, size), Image.LANCZOS)
    out = io.BytesIO(); img.save(out, "JPEG", quality=85, optimize=True)
    replace[im["bufferView"]] = (out.getvalue(), "image/jpeg")
    im["mimeType"] = "image/jpeg"
for i, im in enumerate(gltf["images"]):
    if i not in used_tex:
        im["mimeType"] = "image/png"

new = bytearray()
for idx, bv in enumerate(gltf["bufferViews"]):
    chunk = replace[idx][0] if idx in replace else binary[bv["byteOffset"]:bv["byteOffset"] + bv["byteLength"]]
    while len(new) % 4:
        new.append(0)
    bv["byteOffset"] = len(new)
    bv["byteLength"] = len(chunk)
    new += chunk
while len(new) % 4:
    new.append(0)
gltf["buffers"][0]["byteLength"] = len(new)
js = json.dumps(gltf, separators=(",", ":")).encode()
js += b" " * (-len(js) % 4)
total = 12 + 8 + len(js) + 8 + len(new)
with open(dst, "wb") as f:
    f.write(struct.pack("<4sII", b"glTF", 2, total))
    f.write(struct.pack("<I4s", len(js), b"JSON")); f.write(js)
    f.write(struct.pack("<I4s", len(new), b"BIN\0")); f.write(bytes(new))
print(f"{src} -> {dst}: {len(data)/1e6:.1f} MB -> {total/1e6:.2f} MB")
