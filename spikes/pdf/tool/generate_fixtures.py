#!/usr/bin/env python3
"""Generate deterministic PDF fixtures for the GridFS PDF preview spike."""

from __future__ import annotations

import argparse
import hashlib
import pathlib
import zlib


def _pdf_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def _build_pdf(objects: list[bytes]) -> bytes:
    """Assemble PDF 1.4 bytes from 1-indexed object payloads."""
    out = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets: list[int] = [0]
    for index, payload in enumerate(objects, start=1):
        offsets.append(len(out))
        out.extend(f"{index} 0 obj\n".encode("ascii"))
        out.extend(payload)
        if not payload.endswith(b"\n"):
            out.extend(b"\n")
        out.extend(b"endobj\n")

    xref_offset = len(out)
    count = len(objects) + 1
    out.extend(f"xref\n0 {count}\n".encode("ascii"))
    out.extend(b"0000000000 65535 f \n")
    for off in offsets[1:]:
        out.extend(f"{off:010d} 00000 n \n".encode("ascii"))
    out.extend(
        (
            f"trailer\n<< /Size {count} /Root 1 0 R >>\n"
            f"startxref\n{xref_offset}\n%%EOF\n"
        ).encode("ascii")
    )
    return bytes(out)


def _stream_object(dict_entries: str, data: bytes, compress: bool = True) -> bytes:
    if compress:
        encoded = zlib.compress(data, level=6)
        header = f"<< {dict_entries} /Filter /FlateDecode /Length {len(encoded)} >>\nstream\n"
    else:
        encoded = data
        header = f"<< {dict_entries} /Length {len(encoded)} >>\nstream\n"
    return header.encode("ascii") + encoded + b"\nendstream"


def generate_one_page() -> bytes:
    # Object 1: Catalog, 2: Pages, 3: Font Helvetica, 4: Font Courier, 5: Page 1, 6: Content
    lines = [
        "Queravue GridFS PDF Preview Spike - 1-Page Fixture",
        "Document ID: 673f8c2a1b9e4d0011223344",
        "Bucket: fs (chunks=261120 bytes, cap=32 MiB)",
        "",
        "Sample query output and metadata summary:",
        "SELECT bucket, filename, length, metadata.contentType",
        "FROM fs.files WHERE metadata.contentType = 'application/pdf';",
        "",
        "This single-page PDF exercises in-memory PdfViewer.data loading,",
        "font rendering, and vector stroke borders for baseline latency.",
    ]
    cmds = [
        "0.96 0.97 0.99 rg 36 36 540 720 re f",
        "0.20 0.30 0.48 RG 1.5 w 36 36 540 720 re S",
        "0 0 0 rg",
        "BT /F1 18 Tf 60 720 Td (" + _pdf_escape(lines[0]) + ") Tj ET",
        "0.20 0.30 0.48 RG 1 w 60 708 m 552 708 l S",
        "0.12 0.14 0.18 rg",
    ]
    y = 678
    for i, line in enumerate(lines[1:], start=1):
        font = "/F2 10.5" if 5 <= i <= 6 else "/F1 12"
        cmds.append(f"BT {font} Tf 60 {y} Td ({_pdf_escape(line)}) Tj ET")
        y -= 20
    content = "\n".join(cmds).encode("ascii")

    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [5 0 R] /Count 1 >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>",
        (
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            b"/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents 6 0 R >>"
        ),
        _stream_object("", content, compress=True),
    ]
    return _build_pdf(objects)


def generate_text_300_pages() -> bytes:
    page_count = 300
    # 1: Catalog, 2: Pages, 3: Helvetica, 4: Courier, 5..304: Pages, 305..604: Contents
    objects: list[bytes] = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"",  # placeholder for /Pages
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>",
    ]

    page_refs: list[str] = []
    content_objects: list[bytes] = []
    first_page_obj = 5
    first_content_obj = first_page_obj + page_count

    for p in range(1, page_count + 1):
        page_obj_id = first_page_obj + (p - 1)
        content_obj_id = first_content_obj + (p - 1)
        page_refs.append(f"{page_obj_id} 0 R")

        cmds = [
            f"BT /F1 14 Tf 54 748 Td (Page {p} / {page_count} - Queravue GridFS Text Fixture) Tj ET",
            "0.75 0.78 0.82 RG 0.75 w 54 738 m 558 738 l S",
            "0 0 0 rg",
        ]
        y = 718
        for row in range(1, 41):
            record_id = (p - 1) * 40 + row
            if row % 4 == 0:
                line = (
                    f"{record_id:05d} | SELECT _id, filename, length FROM fs.files "
                    f"WHERE page = {p} ORDER BY uploadDate DESC LIMIT 50;"
                )
            elif row % 4 == 1:
                line = (
                    f'{record_id:05d} | {{"_id": "{record_id:08x}", "bucket": "fs", '
                    f'"page": {p}, "chunk": {row}, "ok": true}}'
                )
            elif row % 4 == 2:
                line = (
                    f"{record_id:05d} | Stream batch {row:02d} on page {p:03d}: "
                    "checking PDFium page layout, font cache, and scroll memory."
                )
            else:
                line = (
                    f"{record_id:05d} | GridFS stores large binary payloads split across "
                    f"chunk documents with 255 KiB default size (doc {record_id})."
                )
            cmds.append(f"BT /F2 8.5 Tf 54 {y} Td ({_pdf_escape(line)}) Tj ET")
            y -= 16

        objects.append(
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            f"/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents {content_obj_id} 0 R >>".encode(
                "ascii"
            )
        )
        content_objects.append(_stream_object("", "\n".join(cmds).encode("ascii"), compress=True))

    objects[1] = f"<< /Type /Pages /Kids [{' '.join(page_refs)}] /Count {page_count} >>".encode("ascii")
    objects.extend(content_objects)
    return _build_pdf(objects)


def _deterministic_noise_block(seed: int, byte_count: int) -> bytes:
    """Produce deterministic pseudo-random bytes that resist zlib compression."""
    chunks: list[bytes] = []
    counter = 0
    remaining = byte_count
    seed_bytes = seed.to_bytes(4, "big")
    while remaining > 0:
        digest = hashlib.blake2b(seed_bytes + counter.to_bytes(4, "big"), digest_size=64).digest()
        if remaining < 64:
            chunks.append(digest[:remaining])
            remaining = 0
        else:
            chunks.append(digest)
            remaining -= 64
        counter += 1
    return b"".join(chunks)


def generate_images_30mib() -> bytes:
    page_count = 15
    width = 1600
    height = 1200
    row_bytes = width * 3
    # ~432 noisy rows per 1200-row RGB image yields ~2.00 MiB compressed per page -> ~30.0 MiB total.
    noisy_rows = 432
    noise_byte_count = noisy_rows * row_bytes

    # 1: Catalog, 2: Pages, 3: Helvetica, 4..18: Pages, 19..33: Image XObjects, 34..48: Contents
    objects: list[bytes] = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"",  # placeholder for /Pages
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    first_page_obj = 4
    first_img_obj = first_page_obj + page_count
    first_content_obj = first_img_obj + page_count

    page_refs: list[str] = []
    img_objects: list[bytes] = []
    content_objects: list[bytes] = []

    for p in range(1, page_count + 1):
        page_obj_id = first_page_obj + (p - 1)
        img_obj_id = first_img_obj + (p - 1)
        content_obj_id = first_content_obj + (p - 1)
        page_refs.append(f"{page_obj_id} 0 R")

        # Bottom/top colored bands compress tightly; middle textured band keeps compressed size ~2.0 MiB.
        top_band = bytes(((p * 37) % 256, (p * 73) % 256, (p * 113) % 256)) * ((height - noisy_rows) // 2 * width)
        mid_noise = _deterministic_noise_block(p, noise_byte_count)
        bottom_rows = height - noisy_rows - ((height - noisy_rows) // 2)
        bottom_band = bytes(((p * 53) % 256, (p * 97) % 256, (p * 29) % 256)) * (bottom_rows * width)
        raw_rgb = top_band + mid_noise + bottom_band

        img_objects.append(
            _stream_object(
                f"/Type /XObject /Subtype /Image /Width {width} /Height {height} "
                "/ColorSpace /DeviceRGB /BitsPerComponent 8",
                raw_rgb,
                compress=True,
            )
        )

        content = (
            f"BT /F1 14 Tf 54 748 Td (Image-Heavy Page {p} / {page_count} - 1600x1200 RGB) Tj ET\n"
            "q 504 0 0 378 54 320 cm /Im1 Do Q\n"
        ).encode("ascii")
        content_objects.append(_stream_object("", content, compress=True))

        objects.append(
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            f"/Resources << /Font << /F1 3 0 R >> /XObject << /Im1 {img_obj_id} 0 R >> >> "
            f"/Contents {content_obj_id} 0 R >>".encode("ascii")
        )

    objects[1] = f"<< /Type /Pages /Kids [{' '.join(page_refs)}] /Count {page_count} >>".encode("ascii")
    objects.extend(img_objects)
    objects.extend(content_objects)
    return _build_pdf(objects)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parent.parent / "build" / "fixtures",
    )
    args = parser.parse_args()
    out_dir: pathlib.Path = args.out
    out_dir.mkdir(parents=True, exist_ok=True)

    specs = [
        ("one_page.pdf", generate_one_page),
        ("text_300_pages.pdf", generate_text_300_pages),
        ("images_30mib.pdf", generate_images_30mib),
    ]
    for name, builder in specs:
        target = out_dir / name
        data = builder()
        target.write_bytes(data)
        mib = len(data) / (1024 * 1024)
        print(f"wrote {target} ({len(data)} bytes, {mib:.2f} MiB)")


if __name__ == "__main__":
    main()
