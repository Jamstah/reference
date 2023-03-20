# Root directory of the project (absolute path).
ROOTDIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

PKG=github.com/distribution/reference

# Project packages.
PACKAGES=$(shell go list ./... | grep -v /vendor/)

WHALE = "+"

# Go files
#
GOFILES=$(shell find . -type f -name '*.go')

# Flags passed to `go test`
TESTFLAGS ?= -v
TESTFLAGS_PARALLEL ?= 8

.PHONY: all build test coverage validate lint validate-git validate-vendor vendor mod-outdated
.DEFAULT: all

all: build

build: ## no binaries to build, so just check compilation
	@echo "$(WHALE) $@"
	@go build -mod=vendor ${PACKAGES}

test: ## run tests, except integration test with test.short
	@echo "$(WHALE) $@"
	@go test -mod=vendor ${TESTFLAGS} ${PACKAGES}

coverage: ## generate coverprofiles from the unit tests
	@echo "$(WHALE) $@"
	@rm -f coverage.txt
	@go test ${TESTFLAGS} ${PACKAGES} 2> /dev/null
	@( for pkg in ${PACKAGES}; do \
		go test ${TESTFLAGS} \
			-cover \
			-coverprofile=profile.out \
			-covermode=atomic $$pkg || exit; \
		if [ -f profile.out ]; then \
			cat profile.out >> coverage.txt; \
			rm profile.out; \
		fi; \
	done )

validate: ## run all validators
	docker buildx bake $@

lint: ## run all linters
	docker buildx bake $@

validate-git: ## validate git
	docker buildx bake $@

validate-vendor: ## validate vendor
	docker buildx bake $@

vendor: ## update vendor
	$(eval $@_TMP_OUT := $(shell mktemp -d -t buildx-output.XXXXXXXXXX))
	docker buildx bake --set "*.output=$($@_TMP_OUT)" update-vendor
	rm -rf ./vendor
	cp -R "$($@_TMP_OUT)"/out/* .
	rm -rf $($@_TMP_OUT)/*

mod-outdated: ## check outdated dependencies
	docker buildx bake $@
