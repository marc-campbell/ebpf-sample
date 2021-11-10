
SHELL := /bin/bash
VERSION ?=`git describe --tags`
DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
VERSION_PACKAGE = github.com/marc-campbell/ebpf-sample/pkg/version
GIT_TREE = $(shell git rev-parse --is-inside-work-tree 2>/dev/null)
ifneq "$(GIT_TREE)" ""
define GIT_UPDATE_INDEX_CMD
git update-index --assume-unchanged
endef
define GIT_SHA
`git rev-parse HEAD`
endef
else
define GIT_UPDATE_INDEX_CMD
echo "Not a git repo, skipping git update-index"
endef
define GIT_SHA
""
endef
endif

UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
define LDFLAGS
-ldflags "\
	-X ${VERSION_PACKAGE}.version=${VERSION} \
	-X ${VERSION_PACKAGE}.gitSHA=${GIT_SHA} \
	-X ${VERSION_PACKAGE}.buildTime=${DATE} \
	-w -extldflags \"-static\" \
"
endef
else # all other OSes, including Windows and Darwin
define LDFLAGS
-ldflags "\
	-X ${VERSION_PACKAGE}.version=${VERSION} \
	-X ${VERSION_PACKAGE}.gitSHA=${GIT_SHA} \
	-X ${VERSION_PACKAGE}.buildTime=${DATE} \
"
endef
endif

CLANG ?= clang-12
CFLAGS := -O2 -g -Wall -Werror $(CFLAGS)

# Image URL to use all building/pushing image targets
IMG ?= controller:latest
# ENVTEST_K8S_VERSION refers to the version of kubebuilder assets to be downloaded by envtest binary.
ENVTEST_K8S_VERSION = 1.22

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
# This is a requirement for 'setup-envtest.sh' in the test target.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.PHONY: all
all: bin


.PHONY: generate
generate: export BPF_CLANG := clang-9
generate: export BPF_CFLAGS := $(CFLAGS)
generate: controller-gen ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	go generate ./pkg/probe/...

.PHONY: fmt
fmt: ## Run go fmt against code.
	go fmt ./pkg/... 

.PHONY: vet
vet: ## Run go vet against code.
	go vet ./pkg/...

.PHONY: test
test: generate fmt vet envtest ## Run tests.
	go test ./pkg/... -coverprofile cover.out

.PHONY: bin
bin: fmt vet
	go build -o ./bin/app ./cmd/app/main.go


