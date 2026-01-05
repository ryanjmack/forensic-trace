# ==============================================================================
# Configuration
# ==============================================================================
SHELL          := /bin/bash
.DELETE_ON_ERROR:

protoc_ver     := 25.1
buf_ver        := 1.50.0

OS_NAME        := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH           := $(shell uname -m)

PROTOC_ARCH    := $(ARCH)
ifeq ($(ARCH),aarch64)
    PROTOC_ARCH := aarch_64
endif
ifeq ($(OS_NAME),darwin)
    OS_NAME := osx
endif

ROOT_DIR       := $(CURDIR)
LOCAL_BIN      := $(ROOT_DIR)/bin
PROTOC         := $(LOCAL_BIN)/protoc
PROTOC_GEN_GO  := $(LOCAL_BIN)/protoc-gen-go
BUF            := $(LOCAL_BIN)/buf

export GOWORK  := $(ROOT_DIR)/go.work
export PATH    := $(LOCAL_BIN):$(PATH)

# Markers
PROTO_FILES    := $(wildcard proto/*.proto)
GO_OUT         := pkg/model/stats.pb.go
TS_OUT         := packages/protocol/src/index.ts

# ==============================================================================
# Targets
# ==============================================================================
.PHONY: all clean test fmt gen deps

all: gen test

deps: $(PROTOC) $(PROTOC_GEN_GO) $(BUF) node_modules
	@go work sync

node_modules: package.json pnpm-lock.yaml
	@pnpm install --frozen-lockfile
	@touch node_modules

# Code Generation
gen: $(PROTOC) $(BUF) $(GO_OUT)

$(GO_OUT) $(TS_OUT): $(PROTO_FILES) buf.gen.yaml
	@echo "Generating protobufs..."
	@$(BUF) generate proto
	@echo "Generating Typescript barrel file..."
	@./packages/protocol/scripts/generate-index.sh
	@$(MAKE) -s fmt

# Testing
test: gen
	@pnpm test
	@echo "Testing Go workspace modules..."
	@go list -m -f '{{.Dir}}' | xargs -I{} bash -c 'cd "{}" && go test ./...'

# Formatting
fmt:
	@pnpm run format
	@echo "Formatting Go workspace modules..."
	@go list -m -f '{{.Dir}}' | xargs -I{} bash -c 'cd "{}" && go fmt ./...'

# Cleaning
clean:
	@rm -rf node_modules $(LOCAL_BIN)
	@rm -f pkg/model/*.pb.go
	@go clean -cache -modcache

# ==============================================================================
# Quality Gates
# ==============================================================================
.PHONY: ci-local
ci-local: deps gen fmt test
	@echo "✅ Local CI pipeline passed deterministic checks."

# ==============================================================================
# Tool Installers
# ==============================================================================
$(LOCAL_BIN):
	@mkdir -p $@

$(PROTOC): | $(LOCAL_BIN)
	@echo "Installing protoc $(protoc_ver)..."
	@curl -sL -o $(LOCAL_BIN)/protoc.zip \
		"https://github.com/protocolbuffers/protobuf/releases/download/v$(protoc_ver)/protoc-$(protoc_ver)-$(OS_NAME)-$(PROTOC_ARCH).zip"
	@unzip -qq -o $(LOCAL_BIN)/protoc.zip bin/protoc -d $(LOCAL_BIN)
	@mv $(LOCAL_BIN)/bin/protoc $(PROTOC)
	@rm -rf $(LOCAL_BIN)/protoc.zip $(LOCAL_BIN)/bin
	@chmod +x $(PROTOC)

$(PROTOC_GEN_GO): | $(LOCAL_BIN)
	@echo "Installing protoc-gen-go..."
	@GOBIN=$(LOCAL_BIN) go install google.golang.org/protobuf/cmd/protoc-gen-go@latest

$(BUF): | $(LOCAL_BIN)
	@echo "Installing buf $(buf_ver)..."
	@curl -sL \
		"https://github.com/bufbuild/buf/releases/download/v$(buf_ver)/buf-$(shell uname -s)-$(shell uname -m)" \
		-o $(BUF)
	@chmod +x $(BUF)
