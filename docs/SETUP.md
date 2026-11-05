# Dev setup (macOS, Homebrew)

```bash
# 0. Xcode (needed for Flutter macOS desktop builds)
#    Install Xcode from the App Store first, then:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept

# 1. Toolchains
brew install go gopls golangci-lint
brew install bufbuild/buf/buf
brew install --cask flutter
brew install cocoapods            # Flutter macOS plugins use CocoaPods

# 2. Docker for test DBs (OrbStack is lighter than Docker Desktop on Apple Silicon)
brew install --cask orbstack      # or: brew install --cask docker

# 3. PATH for Go- and Dart-installed binaries (add to ~/.zshrc)
export PATH="$PATH:$(go env GOPATH)/bin:$HOME/.pub-cache/bin"

# 4. Code generators for protobuf/gRPC
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
dart pub global activate protoc_plugin     # provides protoc-gen-dart

# 5. Verify
go version && gopls version && buf --version && golangci-lint --version
flutter --version && dart --version
flutter doctor                              # macOS desktop line must be ✓
```

Notes:
- macOS desktop support is on by default in current Flutter; if not, run `flutter config --enable-macos-desktop`.
- `dart mcp-server` (used in `.mcp.json`) needs Dart ≥ 3.9, which ships with current Flutter.
- `gopls mcp` needs gopls ≥ 0.20. Upgrade with `brew upgrade gopls`.
- Instead of installing protoc plugins locally, `buf.gen.yaml` can use remote plugins (`buf.build/protocolbuffers/go`, `buf.build/grpc/go`, `buf.build/protocolbuffers/dart`).
