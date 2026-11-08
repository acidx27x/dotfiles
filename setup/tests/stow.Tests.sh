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

assert_status() {
  local expected="$1"
  local status=0
  shift

  "$@" >"$TEST_ROOT/failure.log" 2>&1 || status=$?
  if [[ "$status" != "$expected" ]]; then
    cat "$TEST_ROOT/failure.log" >&2
    fail "Expected exit status $expected, got $status: $*"
  fi
}

snapshot_tree() {
  perl -MDigest::SHA=sha256_hex -MFile::Find -e '
    use strict;
    use warnings;
    my @entries;
    for my $root (@ARGV) {
      if (! -e $root && ! -l $root) {
        push @entries, unpack("H*", $root) . " missing\n";
        next;
      }
      find({ no_chdir => 1, wanted => sub {
        my $path = $File::Find::name;
        my @info = lstat($path) or die "lstat $path: $!";
        my $value = "directory";
        if (-l _) {
          $value = "link " . unpack("H*", readlink($path));
        }
        elsif (-f _) {
          open my $file, "<", $path or die "open $path: $!";
          binmode $file;
          local $/;
          $value = "file " . sha256_hex(<$file> // "");
        }
        push @entries, join(" ", unpack("H*", $path), $info[2], $value) . "\n";
      } }, $root);
    }
    print sort @entries;
  ' -- "$@"
}

assert_unchanged() {
  local expected="$1"
  shift
  snapshot_tree "$@" >"$TEST_ROOT/current.snapshot"
  cmp -s "$expected" "$TEST_ROOT/current.snapshot" || fail "Tree changed: $*"
}

run_wrapper() {
  if ! HOME="$TARGET_HOME" "$WRAPPER" "$@" >"$TEST_ROOT/operation.log" 2>&1; then
    cat "$TEST_ROOT/operation.log" >&2
    fail "Wrapper failed: $*"
  fi
}

new_fixture() {
  CASE_NUMBER=$((CASE_NUMBER + 1))
  FIXTURE_ROOT="$TEST_ROOT/case-$CASE_NUMBER/repository with spaces"
  TARGET_HOME="$TEST_ROOT/case-$CASE_NUMBER/home with spaces"
  WRAPPER="$FIXTURE_ROOT/setup/stow.sh"
  mkdir -p "$FIXTURE_ROOT/setup" "$FIXTURE_ROOT/stow/profiles" "$TARGET_HOME"
  cp -- "$SOURCE_ROOT/setup/stow.sh" "$WRAPPER"
  cp -- "$SOURCE_ROOT/stow/.stow-global-ignore" "$FIXTURE_ROOT/stow/.stow-global-ignore"
  local package
  for package in alpha beta; do
    mkdir -p "$FIXTURE_ROOT/$package/.config/$package" "$FIXTURE_ROOT/$package/.config/shared"
    printf '%s original\n' "$package" >"$FIXTURE_ROOT/$package/.config/$package/config"
    printf '%s shared\n' "$package" >"$FIXTURE_ROOT/$package/.config/shared/$package"
  done
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
command -v perl >/dev/null 2>&1 || fail 'Perl is required for this test.'
BASH_BIN="$(command -v bash)"
STOW_BIN="$(command -v stow)"
CASE_NUMBER=0

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
printf '#!/bin/sh\nprintf "Linux\\n"\n' >"$FIXTURE_ROOT/setup/fake-bin/uname"
chmod +x "$FIXTURE_ROOT/setup/fake-bin/uname"
export PATH="$FIXTURE_ROOT/setup/fake-bin:$PATH"

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
assert_symlink_to "$FIXTURE_ROOT/alpha/nvim-pack-lock.json" "$TARGET_HOME/nvim-pack-lock.json"

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
printf '#!/bin/sh\nprintf "Linux\\n"\n' >"$FIXTURE_ROOT/setup/fake-bin/uname"
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

# Invalid selections must fail before any application changes.
new_fixture
snapshot_tree "$TARGET_HOME" "$FIXTURE_ROOT" >"$TEST_ROOT/before.snapshot"
for selection in '' ',alpha' 'alpha,' 'alpha,,beta' unknown ../alpha -alpha; do
  for action in deploy undeploy restow; do
    assert_status 2 env HOME="$TARGET_HOME" "$WRAPPER" "$action" --package "$selection"
    assert_unchanged "$TEST_ROOT/before.snapshot" "$TARGET_HOME" "$FIXTURE_ROOT"
  done
done
run_wrapper deploy --package alpha,beta,alpha --package beta --dry-run
rg -q 'Preflighting deploy for: alpha beta$' "$TEST_ROOT/operation.log" ||
  fail 'Repeated package options were not deduplicated.'
assert_unchanged "$TEST_ROOT/before.snapshot" "$TARGET_HOME" "$FIXTURE_ROOT"
for content in '' '# comment' 'alpha beta' ' alpha' 'alpha,' unknown ../alpha; do
  printf '%s\n' "$content" >"$FIXTURE_ROOT/stow/profiles/invalid.txt"
  assert_status 2 env HOME="$TARGET_HOME" "$WRAPPER" deploy --profile invalid
done
assert_status 2 env HOME="$TARGET_HOME" "$WRAPPER" deploy --profile ''
assert_status 2 env HOME="$TARGET_HOME" "$WRAPPER" deploy --all
assert_status 2 env HOME="$TARGET_HOME" "$WRAPPER" restow --replace --package alpha
assert_status 2 env HOME="$TARGET_HOME" "$WRAPPER" undeploy --all --package alpha

# Resolve tracked profiles against actual package directories as well as fixture names.
for profile in "$SOURCE_ROOT"/stow/profiles/*.txt; do
  while IFS= read -r package || [[ -n "$package" ]]; do
    case "$package" in '' | \#*) continue ;; esac
    [[ -d "$SOURCE_ROOT/$package" ]] || fail "Profile package does not exist: $package"
    mkdir -p "$FIXTURE_ROOT/$package"
  done <"$profile"
  cp -- "$profile" "$FIXTURE_ROOT/stow/profiles/"
  profile="${profile##*/}"
  run_wrapper deploy --profile "${profile%.txt}" --dry-run
done

# Shared directories expose Stow's otherwise unrelated orphan-link cleanup.
for action in deploy undeploy restow; do
  for change in addition deletion rename conflict; do
    new_fixture
    run_wrapper deploy --package alpha,beta
    for directory in beta shared; do
      source_file="$FIXTURE_ROOT/beta/.config/$directory/config"
      [[ "$directory" != shared ]] || source_file="$FIXTURE_ROOT/beta/.config/shared/beta"
      case "$change" in
        addition | conflict) printf 'pending\n' >"${source_file}-added" ;;
        deletion) rm -- "$source_file" ;;
        rename) mv -- "$source_file" "${source_file}-renamed" ;;
      esac
      if [[ "$change" == conflict ]]; then
        printf 'unmanaged\n' >"$TARGET_HOME/.config/$directory/${source_file##*/}-added"
      fi
    done
    beta_paths=(
      "$TARGET_HOME/.config/beta" "$TARGET_HOME/.config/shared/beta"
      "$TARGET_HOME/.config/shared/beta-added" "$TARGET_HOME/.config/shared/beta-renamed"
    )
    snapshot_tree "${beta_paths[@]}" >"$TEST_ROOT/beta.snapshot"
    snapshot_tree "$FIXTURE_ROOT" >"$TEST_ROOT/source.snapshot"
    run_wrapper "$action" --package alpha
    assert_unchanged "$TEST_ROOT/beta.snapshot" "${beta_paths[@]}"
    assert_unchanged "$TEST_ROOT/source.snapshot" "$FIXTURE_ROOT"
  done
done

for action in deploy restow undeploy; do
  for missing in link directory; do
    new_fixture
    run_wrapper deploy --package alpha,beta
    if [[ "$missing" == link ]]; then
      rm -- "$TARGET_HOME/.config/alpha/config"
    else
      rm -rf -- "$TARGET_HOME/.config/alpha"
    fi
    snapshot_tree "$FIXTURE_ROOT" >"$TEST_ROOT/source.snapshot"
    run_wrapper "$action" --package alpha
    if [[ "$action" == undeploy ]]; then
      assert_absent "$TARGET_HOME/.config/alpha/config"
    else
      [[ ! -L "$TARGET_HOME/.config/alpha" ]] || fail 'Restoration folded the directory.'
      assert_symlink_to "$FIXTURE_ROOT/alpha/.config/alpha/config" \
        "$TARGET_HOME/.config/alpha/config"
    fi
    assert_symlink_to "$FIXTURE_ROOT/beta/.config/beta/config" "$TARGET_HOME/.config/beta/config"
    assert_unchanged "$TEST_ROOT/source.snapshot" "$FIXTURE_ROOT"
  done
done

for action in restow undeploy; do
  for change in file-delete file-rename directory-delete directory-rename; do
    new_fixture
    run_wrapper deploy --package alpha,beta
    case "$change" in
      file-delete) rm -- "$FIXTURE_ROOT/alpha/.config/alpha/config" ;;
      file-rename) mv -- "$FIXTURE_ROOT/alpha/.config/alpha/config" \
        "$FIXTURE_ROOT/alpha/.config/alpha/renamed" ;;
      directory-delete) rm -rf -- "$FIXTURE_ROOT/alpha/.config/alpha" ;;
      directory-rename) mv -- "$FIXTURE_ROOT/alpha/.config/alpha" \
        "$FIXTURE_ROOT/alpha/.config/renamed" ;;
    esac
    snapshot_tree "$FIXTURE_ROOT" >"$TEST_ROOT/source.snapshot"
    run_wrapper "$action" --package alpha
    assert_absent "$TARGET_HOME/.config/alpha/config"
    if [[ "$action" == restow && "$change" == file-rename ]]; then
      assert_symlink_to "$FIXTURE_ROOT/alpha/.config/alpha/renamed" \
        "$TARGET_HOME/.config/alpha/renamed"
    elif [[ "$action" == restow && "$change" == directory-rename ]]; then
      assert_symlink_to "$FIXTURE_ROOT/alpha/.config/renamed/config" \
        "$TARGET_HOME/.config/renamed/config"
    fi
    assert_symlink_to "$FIXTURE_ROOT/beta/.config/shared/beta" "$TARGET_HOME/.config/shared/beta"
    assert_unchanged "$TEST_ROOT/source.snapshot" "$FIXTURE_ROOT"
  done
done

for action in deploy restow undeploy; do
  for conflict in file relative-link absolute-link live-link mismatched-link; do
    new_fixture
    run_wrapper deploy --package alpha
    destination="$TARGET_HOME/.config/alpha/config"
    rm -- "$destination"
    case "$conflict" in
      file) printf 'unmanaged\n' >"$destination" ;;
      relative-link) ln -s missing-foreign "$destination" ;;
      absolute-link) ln -s "$TEST_ROOT/missing-foreign" "$destination" ;;
      live-link) ln -s "$FIXTURE_ROOT/beta/.config/beta/config" "$destination" ;;
      mismatched-link) ln -s '../../../repository with spaces/alpha/missing' "$destination" ;;
    esac
    printf 'deployable first\n' >"$FIXTURE_ROOT/alpha/.config/alpha/aaa"
    snapshot_tree "$TARGET_HOME" "$FIXTURE_ROOT" >"$TEST_ROOT/before.snapshot"
    snapshot_tree "$destination" "$FIXTURE_ROOT" >"$TEST_ROOT/item.snapshot"
    if [[ "$action" == undeploy ]]; then
      run_wrapper undeploy --package alpha
      assert_unchanged "$TEST_ROOT/item.snapshot" "$destination" "$FIXTURE_ROOT"
    else
      assert_status 1 env HOME="$TARGET_HOME" "$WRAPPER" "$action" --package alpha
      assert_unchanged "$TEST_ROOT/before.snapshot" "$TARGET_HOME" "$FIXTURE_ROOT"
    fi
  done
done

for operation in restore-deploy restore-restow remove replace; do
  new_fixture
  run_wrapper deploy --package alpha,beta
  rm -- "$FIXTURE_ROOT/beta/.config/shared/beta"
  case "$operation" in
    restore-deploy | restore-restow) rm -- "$TARGET_HOME/.config/alpha/config" ;;
    remove | replace) mv -- "$FIXTURE_ROOT/alpha/.config/alpha" \
      "$FIXTURE_ROOT/alpha/.config/renamed" ;;
  esac
  snapshot_tree "$TARGET_HOME" "$FIXTURE_ROOT" >"$TEST_ROOT/before.snapshot"
  case "$operation" in
    restore-deploy) run_wrapper deploy --package alpha --dry-run ;;
    restore-restow) run_wrapper restow --package alpha --dry-run ;;
    remove) run_wrapper undeploy --package alpha --dry-run ;;
    replace) run_wrapper deploy --package alpha --replace --dry-run ;;
  esac
  assert_unchanged "$TEST_ROOT/before.snapshot" "$TARGET_HOME" "$FIXTURE_ROOT"
done

new_fixture
ln -s missing "$FIXTURE_ROOT/alpha/.config/alpha/broken"
run_wrapper deploy --package alpha
snapshot_tree "$FIXTURE_ROOT" >"$TEST_ROOT/source.snapshot"
run_wrapper restow --package alpha
[[ -L "$TARGET_HOME/.config/alpha/broken" ]] || fail 'Broken source symlink was lost.'
[[ "$(readlink "$TARGET_HOME/.config/alpha/broken")" == '../../../repository with spaces/alpha/.config/alpha/broken' ]] ||
  fail 'Broken source symlink has the wrong destination.'
run_wrapper undeploy --package alpha
assert_absent "$TARGET_HOME/.config/alpha/broken"
assert_unchanged "$TEST_ROOT/source.snapshot" "$FIXTURE_ROOT"

new_fixture
mkdir -p "$TEST_ROOT/external"
ln -s "$FIXTURE_ROOT/alpha/.config/alpha/config" "$TEST_ROOT/external/config"
ln -s "$TEST_ROOT/external" "$TARGET_HOME/foreign-directory"
snapshot_tree "$TEST_ROOT/external" "$TARGET_HOME/foreign-directory" \
  >"$TEST_ROOT/external.snapshot"
run_wrapper deploy --package alpha
run_wrapper undeploy --package alpha
assert_unchanged "$TEST_ROOT/external.snapshot" \
  "$TEST_ROOT/external" "$TARGET_HOME/foreign-directory"

# A real deployment commonly keeps the repository inside the target home.
new_fixture
mv -- "$FIXTURE_ROOT" "$TARGET_HOME/repository with spaces"
FIXTURE_ROOT="$TARGET_HOME/repository with spaces"
WRAPPER="$FIXTURE_ROOT/setup/stow.sh"
run_wrapper deploy --package alpha
mv -- "$FIXTURE_ROOT/alpha/.config/alpha" "$FIXTURE_ROOT/alpha/.config/renamed"
snapshot_tree "$FIXTURE_ROOT" >"$TEST_ROOT/source.snapshot"
run_wrapper restow --package alpha
assert_absent "$TARGET_HOME/.config/alpha/config"
assert_symlink_to "$FIXTURE_ROOT/alpha/.config/renamed/config" "$TARGET_HOME/.config/renamed/config"
run_wrapper undeploy --package alpha
assert_unchanged "$TEST_ROOT/source.snapshot" "$FIXTURE_ROOT"

new_fixture
HOME="$TARGET_HOME" "$STOW_BIN" --dir="$FIXTURE_ROOT" --target="$TARGET_HOME" alpha
[[ -L "$TARGET_HOME/.config" ]] || fail 'Native Stow did not create a folded fixture.'
snapshot_tree "$FIXTURE_ROOT" >"$TEST_ROOT/source.snapshot"
run_wrapper restow --package alpha
[[ ! -L "$TARGET_HOME/.config" && ! -L "$TARGET_HOME/.config/alpha" ]] ||
  fail 'Restow did not unfold selected directories.'
assert_symlink_to "$FIXTURE_ROOT/alpha/.config/alpha/config" "$TARGET_HOME/.config/alpha/config"
assert_unchanged "$TEST_ROOT/source.snapshot" "$FIXTURE_ROOT"

new_fixture
HOME="$TARGET_HOME" "$STOW_BIN" --dir="$FIXTURE_ROOT" --target="$TARGET_HOME" beta
snapshot_tree "$TARGET_HOME" "$FIXTURE_ROOT" >"$TEST_ROOT/before.snapshot"
assert_status 1 env HOME="$TARGET_HOME" "$WRAPPER" deploy --package alpha
assert_unchanged "$TEST_ROOT/before.snapshot" "$TARGET_HOME" "$FIXTURE_ROOT"

new_fixture
run_wrapper deploy --package alpha,beta
rm -- "$FIXTURE_ROOT/beta/.config/shared/beta"
printf 'new alpha file\n' >"$FIXTURE_ROOT/alpha/.config/shared/beta"
snapshot_tree "$TARGET_HOME" "$FIXTURE_ROOT" >"$TEST_ROOT/before.snapshot"
for action in deploy restow; do
  assert_status 1 env HOME="$TARGET_HOME" "$WRAPPER" "$action" --package alpha
  assert_unchanged "$TEST_ROOT/before.snapshot" "$TARGET_HOME" "$FIXTURE_ROOT"
done

# Replacement and remove-all may clean other packages only when explicitly requested.
new_fixture
run_wrapper deploy --package alpha,beta
rm -rf -- "$FIXTURE_ROOT/beta/.config/beta"
run_wrapper deploy --package alpha --replace
assert_absent "$TARGET_HOME/.config/beta/config"
assert_absent "$TARGET_HOME/.config/shared/beta"
run_wrapper undeploy --all
assert_absent "$TARGET_HOME/.config/alpha/config"

new_fixture
run_wrapper deploy --package alpha,beta
rm -rf -- "$FIXTURE_ROOT/alpha"
assert_status 2 env HOME="$TARGET_HOME" "$WRAPPER" undeploy --package alpha
run_wrapper undeploy --all
[[ -L "$TARGET_HOME/.config/alpha/config" ]] || fail 'Removed package ownership was inferred.'

new_fixture
mkdir -p "$TARGET_HOME/.config/alpha"
printf 'foreign\n' >"$TARGET_HOME/.config/alpha/config"
printf '%s\n' '--adopt' '--override=.*' '--target=/no-such-target' >"$TARGET_HOME/.stowrc"
cp -- "$TARGET_HOME/.stowrc" "$TEST_ROOT/.stowrc"
snapshot_tree "$TARGET_HOME" "$FIXTURE_ROOT" >"$TEST_ROOT/before.snapshot"
assert_status 1 env HOME="$TARGET_HOME" "$WRAPPER" deploy --package alpha
assert_unchanged "$TEST_ROOT/before.snapshot" "$TARGET_HOME" "$FIXTURE_ROOT"

new_fixture
mkdir -p "$TEST_ROOT/missing-bin"
ln -s /usr/bin/dirname "$TEST_ROOT/missing-bin/dirname"
ln -s "$TEST_ROOT/repository with spaces/setup/fake-bin/uname" "$TEST_ROOT/missing-bin/uname"
assert_status 127 env PATH="$TEST_ROOT/missing-bin" HOME="$TARGET_HOME" "$BASH_BIN" "$WRAPPER" \
  deploy --package alpha
rg -q 'Required command not found: stow' "$TEST_ROOT/failure.log" ||
  fail 'Wrong missing-command failure.'

for phase in preflight apply; do
  new_fixture
  mkdir -p "$FIXTURE_ROOT/setup/fake-bin"
  if [[ "$phase" == preflight ]]; then
    printf '#!/usr/bin/env perl\nexit 37;\n' >"$FIXTURE_ROOT/setup/fake-bin/stow"
    expected=37
  else
    cat >"$FIXTURE_ROOT/setup/fake-bin/stow" <<'PERL'
#!/usr/bin/env perl
exit((grep { $_ eq "--simulate" } @ARGV) ? 0 : 43);
PERL
    expected=43
  fi
  chmod +x "$FIXTURE_ROOT/setup/fake-bin/stow"
  assert_status "$expected" env PATH="$FIXTURE_ROOT/setup/fake-bin:$PATH" HOME="$TARGET_HOME" \
    "$WRAPPER" deploy --package alpha
  if rg -q 'Stow operation complete' "$TEST_ROOT/failure.log"; then
    fail 'An engine failure printed successful completion.'
  fi
done

# Fail a later real engine task: earlier changes remain and must not be called a success.
new_fixture
printf 'late file\n' >"$FIXTURE_ROOT/alpha/zzz"
mkdir -p "$TEST_ROOT/perl-modules"
cat >"$TEST_ROOT/perl-modules/StowAuditFail.pm" <<'PERL'
package StowAuditFail;
BEGIN {
  *CORE::GLOBAL::symlink = sub {
    if ($_[1] eq 'zzz') { $! = 13; return 0; }
    return CORE::symlink($_[0], $_[1]);
  };
}
1;
PERL
snapshot_tree "$FIXTURE_ROOT" >"$TEST_ROOT/source.snapshot"
assert_status 13 env PERL5LIB="$TEST_ROOT/perl-modules" PERL5OPT=-MStowAuditFail \
  HOME="$TARGET_HOME" "$WRAPPER" deploy --package alpha
assert_symlink_to "$FIXTURE_ROOT/alpha/.config/alpha/config" "$TARGET_HOME/.config/alpha/config"
assert_absent "$TARGET_HOME/zzz"
assert_unchanged "$TEST_ROOT/source.snapshot" "$FIXTURE_ROOT"
rg -q 'Stow apply failed with exit status 13' "$TEST_ROOT/failure.log" ||
  fail 'Missing apply diagnostic.'
if rg -q 'Stow operation complete' "$TEST_ROOT/failure.log"; then
  fail 'A partial application printed successful completion.'
fi

printf '[PASS] GNU Stow wrapper regression tests completed.\n'
