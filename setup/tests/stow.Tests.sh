#!/usr/bin/env bash

set -Eeuo pipefail

TEST_ROOT=""
TEST_PARENT=""

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

assert_exists() {
  [[ -e "$1" || -L "$1" ]] || fail "Expected path to exist: $1"
}

assert_absent() {
  [[ ! -e "$1" && ! -L "$1" ]] || fail "Expected path to be absent: $1"
}

assert_symlink_to() {
  local expected="$1"
  local link="$2"

  [[ -L "$link" ]] || fail "Expected a symbolic link: $link"
  [[ "$link" -ef "$expected" ]] ||
    fail "Expected '$link' to point to '$expected', got '$(readlink "$link")'."
}

assert_fails() {
  local expected="$1"
  shift

  if "$@" >"$TEST_ROOT/failure.log" 2>&1; then
    fail 'Expected command to fail.'
  fi
  rg -q "$expected" "$TEST_ROOT/failure.log" ||
    fail "Failure output did not match '$expected'."
}

cleanup() {
  if [[ -n "$TEST_ROOT" && -n "$TEST_PARENT" &&
    "$TEST_ROOT" == "$TEST_PARENT"/.tmp-stow-wrapper-tests.* ]]; then
    rm -rf -- "$TEST_ROOT"
  fi
}

trap cleanup EXIT

command -v stow >/dev/null 2>&1 || fail 'GNU Stow is required for this test.'
command -v rg >/dev/null 2>&1 || fail 'ripgrep is required for this test.'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd -P)"
TEST_PARENT="${TMPDIR:-$SOURCE_ROOT}"
TEST_ROOT="$(mktemp -d "$TEST_PARENT/.tmp-stow-wrapper-tests.XXXXXXXX")"
FIXTURE_ROOT="$TEST_ROOT/repository with spaces"
TARGET_HOME="$TEST_ROOT/home with spaces"
WRAPPER="$FIXTURE_ROOT/setup/stow.sh"

mkdir -p \
  "$FIXTURE_ROOT/setup" \
  "$FIXTURE_ROOT/setup/fake-bin" \
  "$FIXTURE_ROOT/stow/profiles" \
  "$FIXTURE_ROOT/alpha/.config/alpha" \
  "$FIXTURE_ROOT/alpha/.codex-test-data" \
  "$FIXTURE_ROOT/beta/.config/beta" \
  "$FIXTURE_ROOT/gamma/.config/gamma" \
  "$TARGET_HOME"
cp -- "$SOURCE_ROOT/setup/stow.sh" "$WRAPPER"
cp -- "$SOURCE_ROOT/stow/.stow-global-ignore" "$FIXTURE_ROOT/stow/.stow-global-ignore"
chmod +x "$WRAPPER"

printf 'alpha\nalpha\n' >"$FIXTURE_ROOT/stow/profiles/common.txt"
printf 'alpha\nbeta\n' >"$FIXTURE_ROOT/stow/profiles/linux.txt"
printf 'gamma\n' >"$FIXTURE_ROOT/stow/profiles/macos.txt"
printf 'alpha\n' >"$FIXTURE_ROOT/alpha/.config/alpha/config"
printf '[user]\n' >"$FIXTURE_ROOT/alpha/.gitconfig"
printf 'ignored\n' >"$FIXTURE_ROOT/alpha/README.md"
printf 'ignored\n' >"$FIXTURE_ROOT/alpha/.gitignore"
printf 'ignored\n' >"$FIXTURE_ROOT/alpha/editor~"
printf 'ignored\n' >"$FIXTURE_ROOT/alpha/.DS_Store"
printf 'ignored\n' >"$FIXTURE_ROOT/alpha/.codex-test-data/file"
printf 'ignored\n' >"$FIXTURE_ROOT/alpha/nvim-pack-lock.json"
printf 'beta\n' >"$FIXTURE_ROOT/beta/.config/beta/config"
printf 'local-only\n' >"$FIXTURE_ROOT/beta/local-only"
printf 'local-only\n' >"$FIXTURE_ROOT/beta/.stow-local-ignore"
printf 'gamma\n' >"$FIXTURE_ROOT/gamma/.config/gamma/config"

cd -- "$TEST_ROOT"

HOME="$TARGET_HOME" "$WRAPPER" deploy --package alpha --dry-run >/dev/null
assert_absent "$TARGET_HOME/.config/alpha/config"

assert_fails 'mutually exclusive' \
  env HOME="$TARGET_HOME" "$WRAPPER" deploy --package alpha --profile common
assert_fails 'only once' \
  env HOME="$TARGET_HOME" "$WRAPPER" deploy --profile common --profile linux
assert_fails 'Invalid profile name' \
  env HOME="$TARGET_HOME" "$WRAPPER" deploy --profile common,linux

HOME="$TARGET_HOME" "$WRAPPER" deploy --package alpha >/dev/null
assert_symlink_to \
  "$FIXTURE_ROOT/alpha/.config/alpha/config" \
  "$TARGET_HOME/.config/alpha/config"
assert_symlink_to "$FIXTURE_ROOT/alpha/.gitconfig" "$TARGET_HOME/.gitconfig"
assert_absent "$TARGET_HOME/README.md"
assert_absent "$TARGET_HOME/.gitignore"
assert_absent "$TARGET_HOME/editor~"
assert_absent "$TARGET_HOME/.DS_Store"
assert_absent "$TARGET_HOME/.codex-test-data"
assert_absent "$TARGET_HOME/nvim-pack-lock.json"

HOME="$TARGET_HOME" "$WRAPPER" deploy --package alpha >/dev/null
HOME="$TARGET_HOME" "$WRAPPER" deploy --package alpha,beta,alpha >/dev/null
assert_exists "$TARGET_HOME/.config/alpha/config"
assert_exists "$TARGET_HOME/.config/beta/config"
assert_absent "$TARGET_HOME/local-only"
assert_absent "$TARGET_HOME/.stow-local-ignore"

HOME="$TARGET_HOME" "$WRAPPER" undeploy --package alpha >/dev/null
assert_absent "$TARGET_HOME/.config/alpha/config"
assert_exists "$TARGET_HOME/.config/beta/config"

printf 'added\n' >"$FIXTURE_ROOT/beta/.config/beta/added"
HOME="$TARGET_HOME" "$WRAPPER" restow --package beta >/dev/null
assert_exists "$TARGET_HOME/.config/beta/added"

HOME="$TARGET_HOME" "$WRAPPER" deploy --profile common --replace >/dev/null
assert_exists "$TARGET_HOME/.config/alpha/config"
assert_absent "$TARGET_HOME/.config/beta/config"

HOME="$TARGET_HOME" "$WRAPPER" deploy --package stow >/dev/null
assert_exists "$TARGET_HOME/.stow-global-ignore"
assert_absent "$TARGET_HOME/profiles"

HOME="$TARGET_HOME" "$WRAPPER" undeploy --all >/dev/null
assert_absent "$TARGET_HOME/.config/alpha/config"

printf '#!/bin/sh\nprintf "Darwin\\n"\n' >"$FIXTURE_ROOT/setup/fake-bin/uname"
chmod +x "$FIXTURE_ROOT/setup/fake-bin/uname"
PATH="$FIXTURE_ROOT/setup/fake-bin:$PATH" HOME="$TARGET_HOME" \
  "$WRAPPER" deploy >/dev/null
assert_exists "$TARGET_HOME/.config/gamma/config"

HOME="$TARGET_HOME" "$WRAPPER" undeploy --all >/dev/null
HOME="$TARGET_HOME" "$WRAPPER" deploy >/dev/null
assert_exists "$TARGET_HOME/.config/alpha/config"
assert_exists "$TARGET_HOME/.config/beta/config"

HOME="$TARGET_HOME" "$WRAPPER" undeploy --all >/dev/null
mkdir -p "$TARGET_HOME/.config/gamma"
printf 'unmanaged\n' >"$TARGET_HOME/.config/gamma/config"
printf '%s\n' '--adopt' >"$TARGET_HOME/.stowrc"
printf '%s\n' '--adopt' >"$TEST_ROOT/.stowrc"
assert_fails 'conflict|CONFLICT' \
  env HOME="$TARGET_HOME" "$WRAPPER" deploy --package gamma
[[ "$(cat "$TARGET_HOME/.config/gamma/config")" == 'unmanaged' ]] ||
  fail 'A failed deployment changed an unmanaged file.'
[[ "$(cat "$FIXTURE_ROOT/gamma/.config/gamma/config")" == 'gamma' ]] ||
  fail 'The wrapper honored an unsafe --adopt option from the user .stowrc.'

assert_fails 'Unknown or excluded Stow package' \
  env HOME="$TARGET_HOME" "$WRAPPER" deploy --package unknown
assert_fails 'Unknown Stow profile' \
  env HOME="$TARGET_HOME" "$WRAPPER" deploy --profile unknown

printf '[PASS] GNU Stow wrapper regression tests completed.\n'
