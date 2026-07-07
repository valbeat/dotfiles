"""Extract the embedded thumbnail (TEST block) from a .blend file and save as PNG.

Works without Blender installed. Supports uncompressed, gzip, and zstd
(Blender 3.0+) compressed .blend files.

Usage: python3 extract_thumb.py <file.blend> <out.png>
"""
import gzip, io, struct, sys, zlib


def open_blend(path):
    raw = open(path, "rb")
    magic = raw.read(4)
    raw.seek(0)
    if magic[:2] == b"\x1f\x8b":
        return gzip.open(raw)
    if magic == b"\x28\xb5\x2f\xfd":
        try:
            import zstandard
        except ImportError:
            sys.exit("zstd-compressed blend file: pip install zstandard")
        return zstandard.ZstdDecompressor().stream_reader(raw)
    return raw


def write_png(path, width, height, rgba):
    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c))

    # Blender stores pixels bottom-to-top; flip rows and add filter byte 0
    stride = width * 4
    raw = b"".join(
        b"\x00" + rgba[y * stride:(y + 1) * stride]
        for y in range(height - 1, -1, -1)
    )
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def read_exact(f, n):
    buf = b""
    while len(buf) < n:
        part = f.read(n - len(buf))
        if not part:
            return buf
        buf += part
    return buf


def main():
    blend_path, out_path = sys.argv[1], sys.argv[2]
    f = open_blend(blend_path)
    header = read_exact(f, 12)
    if header[:7] != b"BLENDER":
        sys.exit("not a blend file")
    psize = 8 if header[7:8] == b"-" else 4
    endian = "<" if header[8:9] == b"v" else ">"
    bh_len = 4 + 4 + psize + 4 + 4
    while True:
        bh = read_exact(f, bh_len)
        if len(bh) < bh_len:
            sys.exit("TEST block not found (no thumbnail saved in this file)")
        code = bh[:4]
        size = struct.unpack(endian + "I", bh[4:8])[0]
        if code == b"TEST":
            data = read_exact(f, size)
            w, h = struct.unpack(endian + "ii", data[:8])
            rgba = data[8:8 + w * h * 4]
            write_png(out_path, w, h, rgba)
            print(f"thumbnail: {w}x{h} -> {out_path}")
            return
        if code == b"ENDB":
            sys.exit("TEST block not found (no thumbnail saved in this file)")
        # seek() is unreliable on compressed streams; read and discard
        read_exact(f, size)


if __name__ == "__main__":
    main()
