# Makefile for gh CLI development

DEFAULT_GOAL := help

GO_LDFLAGS := -X github.com/cli/cli/v2/internal/build.Version=$(GH_VERSION) \
	-X github.com/cli/cli/v2/internal/build.Date=$(shell date -u '+%Y-%m-%d')

GH_VERSION ?= $(shell git describe --tags 2>/dev/null || echo "v0.0.0-dev")

BIN_DIR ?= bin
BIN_NAME ?= gh
BIN_PATH := $(BIN_DIR)/$(BIN_NAME)

SRC := $(shell find . -name '*.go' -not -path './vendor/*')

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: $(BIN_PATH) ## Build the gh binary

$(BIN_PATH): $(SRC)
	@mkdir -p $(BIN_DIR)
	go build -trimpath -ldflags "$(GO_LDFLAGS)" -o $(BIN_PATH) ./cmd/gh

.PHONY: install
install: ## Install gh to GOPATH/bin
	go install -trimpath -ldflags "$(GO_LDFLAGS)" ./cmd/gh

.PHONY: test
test: ## Run unit tests
	go test ./...

.PHONY: test-race
test-race: ## Run unit tests with race detector
	go test -race ./...

# Added -count=1 to disable test result caching, useful when debugging flaky tests
.PHONY: test-nocache
test-nocache: ## Run unit tests without cache
	go test -count=1 ./...

.PHONY: lint
lint: ## Run golint
	golint ./...

.PHONY: vet
vet: ## Run go vet
	go vet ./...

.PHONY: fmt
fmt: ## Format Go source files
	gofmt -w $(SRC)

.PHONY: fmt-check
fmt-check: ## Check if Go source files are formatted
	@diff=$$(gofmt -d $(SRC)); \
	if [ -n "$$diff" ]; then \
		echo "$$diff"; \
		exit 1; \
	fi

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf $(BIN_DIR)

.PHONY: deps
deps: ## Download Go module dependencies
	go mod download

.PHONY: tidy
tidy: ## Tidy Go module dependencies
	go mod tidy

.PHONY: generate
generate: ## Run go generate
	go generate ./...

.PHONY: manpages
manpages: build ## Generate man pages
	$(BIN_PATH) docs --type man --doc-path ./share/man/man1/

.PHONY: completions
completions: build ## Generate shell completions
	@mkdir -p share/completions
	$(BIN_PATH) completion -s bash > share/completions/gh.bash
	$(BIN_PATH) completion -s zsh > share/completions/gh.zsh
	$(BIN_PATH) completion -s fish > share/completions/gh.fish
