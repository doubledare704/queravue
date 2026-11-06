# Queravue developer tasks. Run `make help` for a list.

VERSION    ?= 0.1.0-dev
CORE_BIN   := core/bin/queravued
LDFLAGS    := -s -w -X github.com/doubledare704/queravue/core/internal/version.Version=$(VERSION)
COMPOSE    := docker compose -f dev/docker-compose.yml
DART_FILES  = $(shell find app/lib app/test app/integration_test app/test_driver -name '*.dart' -not -path '*/gen/*')

.DEFAULT_GOAL := help
.PHONY: help proto core app-run test test-core test-app test-integration test-e2e test-e2e-mongo test-perf lint lint-proto lint-core lint-app db-up db-down

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

proto: ## Lint the contract and regenerate Go + Dart code
	cd proto && buf format -w && buf lint && buf generate

core: ## Build the core sidecar into core/bin/
	cd core && CGO_ENABLED=0 go build -trimpath -ldflags '$(LDFLAGS)' -o bin/queravued ./cmd/queravued

# The "Embed queravued" Xcode build phase copies $(CORE_BIN) into
# Queravue.app/Contents/MacOS/ on every macOS build, so the binary survives
# Flutter rebuilding the bundle.
app-run: core ## Build the core, embed it in the app bundle, run the app
	cd app && flutter run -d macos

test: test-core test-app ## Run core and app unit tests

test-core:
	cd core && go test -race ./...

test-app:
	cd app && flutter test

test-integration: db-up ## Run core integration tests against the docker DBs (QUERAVUE_IT_KEYCHAIN=1 uses the real keychain)
	cd core && go test -count=1 -tags=integration ./...

test-e2e: core ## Run the macOS integration test (real app + core, kill -9 recovery)
	cd app && flutter test integration_test/core_lifecycle_test.dart -d macos

test-e2e-mongo: core ## Mongo UI flow against the seeded docker replica set (make db-up; --profile seed up mongo-seed)
	cd app && flutter test integration_test/documents_test.dart -d macos

test-perf: db-up core ## Grid perf budget: 1M rows through the real core and Postgres (profile build)
	cd app && flutter drive --profile -d macos --driver=test_driver/perf_driver.dart --target=integration_test/grid_perf_test.dart

lint: lint-proto lint-core lint-app ## Run all linters

lint-proto:
	cd proto && buf format --diff --exit-code && buf lint

lint-core:
	cd core && golangci-lint run --build-tags=integration

lint-app:
	cd app && flutter analyze
	dart format --output=none --set-exit-if-changed $(DART_FILES)

db-up: ## Start test databases and wait until healthy
	$(COMPOSE) up -d --wait --wait-timeout 600

db-down: ## Stop test databases (data volumes are kept)
	$(COMPOSE) down
