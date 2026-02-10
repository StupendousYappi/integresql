set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

go_module_name := "github.com/allaboutapps/integresql"
arg_commit := `git rev-list -1 HEAD 2> /dev/null || echo "unknown"`
arg_build_date := `date -Is 2> /dev/null || date 2> /dev/null || echo "unknown"`
ldflags := "-X '{{go_module_name}}/internal/config.ModuleName={{go_module_name}}' -X '{{go_module_name}}/internal/config.Commit={{arg_commit}}' -X '{{go_module_name}}/internal/config.BuildDate={{arg_build_date}}'"

# Show available recipes.
default: help

# Default `just` recipe: go-format, go-build, and lint.
build: go-format go-build lint

# Runs all common recipes: clean, init, build, and test.
all: clean init build test

# Prints additional info.
info: info-go

# (opt) Prints go.mod updates, module-name, and current go version.
info-go:
  @echo "[go.mod]" > tmp/.info-go
  @just get-go-outdated-modules >> tmp/.info-go
  @just info-module-name >> tmp/.info-go
  @go version >> tmp/.info-go
  @cat tmp/.info-go

# Runs golangci-lint.
lint: go-lint

# (opt) Runs go format.
go-format:
  go fmt ./...

# (opt) Runs go build.
go-build:
  go build -ldflags "{{ldflags}}" -o bin/integresql ./cmd/server

# (opt) Runs golangci-lint.
go-lint:
  golangci-lint run --timeout 5m

# Run tests, output by package, print coverage.
bench:
  @go test -benchmem=false -run=./... -bench . github.com/allaboutapps/integresql/tests -race -count=4 -v

# Run tests, output by package, print coverage.
test: go-test-by-pkg go-test-print-coverage

# (opt) Run tests, output by package.
go-test-by-pkg:
  gotestsum --format pkgname-and-test-fails --format-hide-empty-pkg --jsonfile /tmp/test.log -- -race -cover -count=1 -coverprofile=/tmp/coverage.out ./...

# (opt) Run tests, output by testname.
go-test-by-name:
  gotestsum --format testname --jsonfile /tmp/test.log -- -race -cover -count=1 -coverprofile=/tmp/coverage.out ./...

# (opt) Print overall test coverage (must be done after running tests).
go-test-print-coverage:
  @printf "coverage "
  @go tool cover -func=/tmp/coverage.out | tail -n 1 | awk '{$1=$1;print}'

# (opt) Prints outdated (direct) go modules (from go.mod).
get-go-outdated-modules:
  @((go list -u -m -f '{{"{{"}}if and .Update (not .Indirect){{"}}"}}{{"{{"}}.{{"}}"}}{{"{{"}}end{{"}}"}}' all) 2>/dev/null | grep " ") || echo "go modules are up-to-date."

# Runs modules, tools, and tidy.
init: modules tools tidy
  @go version

# (opt) Cache packages as specified in go.mod.
modules:
  go mod download

# (opt) Install packages as specified in tools.go.
tools:
  @cat tools.go | grep _ | awk -F'"' '{print $2}' | xargs -P "$(nproc)" -tI % go install %

# (opt) Tidy go.sum.
tidy:
  go mod tidy

# Wizard to drop and create the development database.
reset:
  @echo "DROP & CREATE database:"
  @echo "  PGHOST=${PGHOST} PGDATABASE=${PGDATABASE} PGUSER=${PGUSER}"
  @echo -n "Are you sure? [y/N] " && read ans && [ "${ans:-N}" = y ]
  psql -d postgres -c 'DROP DATABASE IF EXISTS "${PGDATABASE}";'
  psql -d postgres -c 'CREATE DATABASE "${PGDATABASE}" WITH OWNER ${PGUSER} TEMPLATE "template0"'

# Prints licenses of embedded modules in compiled bin/integresql.
get-licenses:
  lichen bin/integresql

# Prints embedded modules in compiled bin/integresql.
get-embedded-modules:
  go version -m -v bin/integresql

# (opt) Prints count of embedded modules in compiled bin/integresql.
get-embedded-modules-count:
  go version -m -v bin/integresql | grep $'\tdep' | wc -l

# Cleans tmp folders.
clean:
  @echo "just clean"
  @rm -rf tmp/* 2> /dev/null
  @rm -rf api/tmp/* 2> /dev/null

# Prints current go module-name (pipeable).
get-module-name:
  @echo "{{go_module_name}}"

# (opt) Prints current go module-name.
info-module-name:
  @echo "go module-name: '{{go_module_name}}'"

# (opt) Prints used -ldflags for go-build.
get-go-ldflags:
  @echo "{{ldflags}}"

# Show common recipes.
help:
  @echo "usage: just <recipe>"
  @echo "note: use 'just help-all' to see all recipes."
  @echo ""
  @just --list | grep --invert-match "(opt)"

# Show all recipes.
help-all:
  @echo "usage: just <recipe>"
  @echo "note: recipes flagged with '(opt)' are part of a main recipe."
  @echo ""
  @just --list
