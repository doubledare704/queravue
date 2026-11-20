# PDF preview spike (`pdfrx` vs. system viewer)

Time-boxed spike for [ADR 0023 §6](../../docs/adr/0023-gridfs.md#6-pdf) evaluating how Queravue's GridFS viewer should preview PDFs (up to the 32 MiB preview cap) received as bytes over gRPC.

**Decision:** Use the **system viewer** (write streamed bytes to a sanitized temporary file and launch the OS default PDF app; zero new packages). Reject `pdfrx`: even unused in a macOS release build, linking it adds **+17.62 MiB (+18.48 MB)** of idle RSS and **+30.61 MiB (+32.09 MB)** to the app bundle, pushing Queravue's `139.4 MiB` (`146.2 MB`) combined idle baseline to **~157 MiB (~165 MB)** — past the **150 MB** idle memory budget before a user opens a PDF.

---

## Test environment

- **Date:** 2026-11-20
- **Machine:** Apple M4 Pro (arm64), macOS 27.2.1 (Build `26B131`)
- **Tooling:** Flutter 3.47.9, Dart 3.13.7, CocoaPods 1.17.0
- **Candidate:** `pdfrx` `3.0.0` (`pdfrx_engine` `0.9.3`, `pdfium_flutter` `0.4.3`, `pdfium_dart` `0.4.3`, PDFium `chromium/8125` / `158.0.8125.0`, non-V8/non-XFA)
- **Window & build mode:** macOS `--release` universal binary (`arm64` + `x86_64`), fixed `1440×900` window, `app-sandbox = false` (matching `app/macos/Runner/Release.entitlements`)
- **Fixtures (generated in `build/fixtures/`):**
  1. `one_page.pdf` — `1,141` bytes, 1 page (text + vector border)
  2. `text_300_pages.pdf` — `315,821` bytes (`0.30 MiB`), 300 pages (40 lines/page text, FlateDecode streams)
  3. `images_30mib.pdf` — `31,203,364` bytes (`29.76 MiB`), 15 pages (each with a `1600×1200` RGB `FlateDecode` image)

---

## Measurements (macOS release builds)

### 1. Bundle size & idle RSS

| Metric | Baseline (no `pdfrx`) | With `pdfrx 3.0.0` | Delta | Budget / Impact |
|---|---:|---:|---:|---|
| `.app` bundle (apparent bytes) | `36.68 MiB` (`38.46 MB`) | `67.29 MiB` (`70.55 MB`) | **`+30.61 MiB` (`+32.09 MB`)** | +83.5% bundle growth |
| `.app` bundle (`du -sk`) | `37,612 KiB` | `68,992 KiB` | **`+31,380 KiB`** | — |
| Idle RSS at 30 s, unused (median ×3, Dart) | `144.67 MiB` (`151.70 MB`) | `162.30 MiB` (`170.18 MB`) | **`+17.62 MiB` (`+18.48 MB`)** | Exceeds 150 MB budget (`139.4` → `~157.0 MiB`) |
| Idle RSS at 30 s, eager `pdfrxFlutterInitialize()` (median ×3) | `144.67 MiB` (`151.70 MB`) | `164.47 MiB` (`172.46 MB`) | **`+19.80 MiB` (`+20.76 MB`)** | `139.4` → `~159.2 MiB` |

**Why the bundle grows by +30.61 MiB:**
- `PDFium.framework` (universal `x86_64` + `arm64`, SwiftPM): `14.54 MiB` (`15.25 MB`)
- `pdfium_dart.framework` (duplicate universal `x86_64` + `arm64` PDFium dylib): `11.87 MiB` (`12.45 MB`) — `pdfium_dart 0.4.3`'s `hook/link.dart` only strips the duplicate native-asset dylib on iOS, keeping it on macOS so `flutter test` can load it directly. Even removing that duplicate leaves **`~+18.7 MiB` (`~+19.6 MB`)**.
- `App.framework` Dart AOT snapshot growth (`pdfrx` + `pdfrx_engine` + `material_ui` + transitive deps): `+3.50 MiB` (`+3.67 MB`)
- `objective_c.framework`: `0.35 MiB` (`0.37 MB`); `pdfrx_pdfium_gate.framework`: `0.16 MiB` (`0.17 MB`).

**Why idle RSS grows by +17.62 MiB even unused:** `otool -L` confirms `Contents/MacOS/pdf_spike` links `@rpath/PDFium.framework/PDFium` via `LC_LOAD_DYLIB`, mapping PDFium into the process at launch alongside the larger AOT snapshot (`+3.67 MB`).

### 2. In-app `pdfrx` per-fixture rendering, scrolling, and close RSS

All fixtures loaded via `PdfViewer.data(Uint8List, ...)` (no path passed to `pdfrx`). Medians of 3 fresh release runs each; "Time to first page" measures from mounting `PdfViewer.data` until `visibleRenderState == PdfVisibleRenderState.ready` and `endOfFrame` completes.

| Fixture | Size / Pages | Painted pages | `onViewerReady` | Time to 1st page (runs) | RSS before load | Peak RSS while showing (Dart / `ps`) | RSS 5 s after close | RSS 10 s after close |
|---|---|---|---|---:|---:|---:|---:|---:|
| `one_page.pdf` | `1.1 KiB` / 1 p | 1 | `14 ms` | **`313 ms`** (`315, 313, 308`) | `134.03 MiB` | `201.20 MiB` (`204.89 MiB`) | `187.09 MiB` | **`187.08 MiB`** (`+53.05 MiB`) |
| `text_300_pages.pdf` | `0.30 MiB` / 300 p | 95 (stops pp 1–15, 50..300) | `16 ms` | **`160 ms`** (`157, 165, 160`) | `143.83 MiB` | `318.14 MiB` (`314.08 MiB`) | `277.95 MiB` | **`284.89 MiB`** (`+141.06 MiB`) |
| `images_30mib.pdf` | `29.76 MiB` / 15 p | 15 (all 15 pages) | `15 ms` | **`165 ms`** (`165, 165, 157`) | `143.95 MiB` | `398.08 MiB` (`392.50 MiB`) | `372.39 MiB` | **`372.33 MiB`** (`+228.38 MiB`) |

Additional observations:
- Opening `one_page.pdf` is slower (`313 ms`) than subsequent runs because `PdfViewer` lazily runs `pdfrxFlutterInitialize()` (spawns `BackgroundWorker`, calls `FPDF_InitLibrary()`, and scans system fonts) on first open; once initialized, page 1 paints in `160–165 ms` (or `148–157 ms` in `pdfrx_sequence`).
- **Post-close retention:** Unmounting `PdfViewer` and dropping the `Uint8List` reference did **not** return RSS to baseline. Clearing Flutter's `PaintingBinding.instance.imageCache` left `images_30mib` at `370.25 MiB`. A sequential session (`one_page` → close 5 s → `text_300` → close 5 s → `images_30mib` → close 10 s) peaked at `384.94 MiB` (`401.16 MiB` kernel `maxRss`) and remained at `374.52 MiB` 10 s after closing the third file.

### 3. System viewer (`open` / `start` / `xdg-open`)

`app/pubspec.yaml` does not include `url_launcher`, so option 2 uses `dart:io` `Process` directly (zero new dependencies). Measured in the baseline release build with `open -g` on macOS:

| Fixture | Temp-file write (`flush: true`) | OS launch (`open -g`) | Added bundle size | Idle RSS delta |
|---|---:|---:|---:|---:|
| `one_page.pdf` (`1.1 KiB`) | `4 ms` | `91 ms` (exit `0`) | `0 B` | `0 MiB` |
| `text_300_pages.pdf` (`0.30 MiB`) | `5 ms` | `64 ms` (exit `0`) | `0 B` | `0 MiB` |
| `images_30mib.pdf` (`29.76 MiB`) | `10 ms` | `86 ms` (exit `0`) | `0 B` | `0 MiB` |

Note: In this spike, `loadFixtureBytes` read the 30 MiB fixture into a `Uint8List` before writing, temporarily bumping baseline RSS to `206 MiB` during `images_30mib`; in Queravue's GridFS viewer, `GridFsService.Download` streams `≤ 1 MiB` chunks over gRPC straight to the temp file's `IOSink`, keeping app memory flat and delegating PDF parsing/rendering RSS entirely to the OS viewer process.

---

## Licensing & cross-platform notes (`pdfrx`)

### Licensing of `pdfrx` and bundled PDFium binaries
- **`pdfrx` / `pdfrx_engine` / `pdfium_dart` / `pdfium_flutter`:** MIT License.
- **`espresso3389/pdfium-xcframework` & `bblanchon/pdfium-binaries` build/packaging repos:** MIT License; distribute non-V8, non-XFA PDFium builds (`pdf_enable_v8 = false`, `pdf_enable_xfa = false`, `pdf_use_partition_alloc = false`).
- **PDFium itself:** BSD 3-Clause (`Copyright 2014 The PDFium Authors`) + Apache 2.0.
- **Embedded third-party C/C++ libraries inside the PDFium binary** (not automatically added to Flutter's `LicenseRegistry` by `pdfrx` or `pdfium_flutter`): FreeType (FTL, requires documentation/about acknowledgment), libjpeg-turbo (IJG / BSD), libpng, zlib, OpenJPEG, libtiff, Little CMS 2 (`lcms2`), ICU, Abseil, Highway, `agg23`, `simdutf`, etc. Shipping `pdfrx` requires bundling and displaying these third-party notices manually.

### Windows & Linux support (`pdfrx`)
- **Native asset delivery:** `pdfium_dart` downloads `pdfium-win-{x64,arm64,x86}.tgz` (`pdfium.dll`) or `pdfium-linux-{x64,arm64,arm,x86}.tgz` (`libpdfium.so`) from `bblanchon/pdfium-binaries` over HTTPS during the Dart build hook (`hook/build.dart`, SHA-256 verified), requiring network access (or proxy config) on clean builds.
- **C toolchain required everywhere:** Every native platform build compiles a small C library (`pdfrx_pdfium_gate`) via `native_toolchain_c` (MSVC on Windows, Clang/GCC on Linux, Xcode on macOS).
- **Windows Developer Mode:** `pdfrx` explicitly requires Windows **Developer Mode** enabled because build-time symlinks fail without it.
- **Linux bundling:** `pdfium_dart` resolves `libpdfium.so` from `<executable_dir>/lib/libpdfium.so` (Flutter's standard bundle `lib/` directory), falling back to `.dart_tool/native_assets.yaml`.
- **Transitive footprint:** Adding `pdfrx` pulls 52 transitive packages (including `url_launcher`, `path_provider`, `image`, `archive`, `http`, `rxdart`, `jni`, `objective_c`, `material_ui`).

### System viewer cross-platform & security notes
- **Commands (zero dependencies):**
  - macOS: `/usr/bin/open <temp_file.pdf>`
  - Windows: `cmd /c start "" <temp_file.pdf>`
  - Linux: `xdg-open <temp_file.pdf>` (`ProcessStartMode.detached` so the viewer does not block the app)
- **Temp-file hygiene:** Create a private temp subdirectory (`0700` on POSIX), sanitize the GridFS filename (strip path separators and leading dots, restrict characters, force `.pdf` suffix), write with `0600` permissions on POSIX, and clean up tracked temp files/dirs on app or session exit.
- **macOS App Sandbox note (Iteration 19):** `app/macos/Runner/Release.entitlements` currently sets `com.apple.security.app-sandbox = false`. When App Sandbox is enabled for distribution, verify launching temp PDFs in Preview (e.g. via `NSWorkspace.shared.open` or user-accessible temporary directory entitlements).

---

## Reproducing

```bash
cd spikes/pdf

# 1. Unit tests & static analysis
flutter pub get && flutter analyze && flutter test

# 2. Generate deterministic PDFs only
python3 tool/generate_fixtures.py

# 3. Full automated macOS release benchmark (builds baseline + pdfrx, runs 3x idle/fixtures)
./tool/measure.sh

# 4. Interactive manual spike app
flutter run -d macos --release
```

Raw per-run JSON reports and the combined `summary.json` are written to `spikes/pdf/build/perf/` (gitignored).
