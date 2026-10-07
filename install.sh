#!/bin/sh
# Deskie installer.
#
#   curl -fsSL https://raw.githubusercontent.com/Aditya-A-G/deskie/main/install.sh | sh
#
# Installs the Deskie app into ~/Applications (never sudo), starts it, and adds the Claude Code plugin with the
# `claude` CLI. Safe to run again: an up-to-date app is kept as is, and the plugin steps skip what is already there.
#
# The version: the one the Claude Code plugin pins (plugin/config.sh in this repo), so the plugin never downloads the
# app again right after this. Newer releases come through Deskie's own updater.
#
# Overrides (development and tests):
#   DESK_BUDDY_APP_VERSION=0.1.2                    install this version
#   DESK_BUDDY_RELEASE_URL=http://host/{file}       release URL template ({version}, {file})
#   DESK_BUDDY_APPS_DIR=/some/dir                   install here instead of ~/Applications
#   DESK_BUDDY_HOME=/some/dir                       Deskie's data folder instead of ~/.desk-buddy (passed to the app)
#   DESK_BUDDY_OPEN_CMD=/path/to/open               replace `open`
#   DESK_BUDDY_HEALTH_WAIT=15                       seconds to wait for Deskie to answer after starting it
#   DESK_BUDDY_MARKETPLACE=/path/to/local/copy      the plugin marketplace to add (a local copy or owner/repo),
#                                                   to try an unpublished plugin; default Aditya-A-G/deskie
#
# Written for POSIX sh (macOS /bin/sh), and wrapped in main() so a cut-off download runs nothing.

PINNED_VERSION="0.1.2"
DEFAULT_RELEASE_URL='https://github.com/Aditya-A-G/deskie/releases/download/v{version}/{file}'

main() {
  set -u
  umask 022
  VERSION="${DESK_BUDDY_APP_VERSION:-$PINNED_VERSION}"
  RELEASE_URL="${DESK_BUDDY_RELEASE_URL:-$DEFAULT_RELEASE_URL}"
  APPS_DIR="${DESK_BUDDY_APPS_DIR:-$HOME/Applications}"
  HOME_DIR="${DESK_BUDDY_HOME:-$HOME/.desk-buddy}"
  OPEN_CMD="${DESK_BUDDY_OPEN_CMD:-open}"
  MARKETPLACE="${DESK_BUDDY_MARKETPLACE:-Aditya-A-G/deskie}"
  APP="$APPS_DIR/Deskie.app"
  STAGE=""
  trap 'cleanup' EXIT
  trap 'exit 130' INT TERM

  if [ -t 1 ]; then B="$(printf '\033[1m')"; D="$(printf '\033[2m')"; R="$(printf '\033[0m')"; else B=""; D=""; R=""; fi

  case "$VERSION" in
    [0-9]*.[0-9]*) ;;
    *) fail "Unknown Deskie version: $VERSION" ;;
  esac
  case "$VERSION" in *[!0-9A-Za-z.-]*) fail "Unknown Deskie version: $VERSION" ;; esac

  say "${B}Installing Deskie${R}"

  # 1. The Mac
  [ "$(uname -s)" = "Darwin" ] || fail "Deskie runs on macOS only."
  macos="$(sw_vers -productVersion 2>/dev/null)"
  case "$macos" in
    [0-9]*) major="${macos%%.*}"
            case "$major" in *[!0-9]*) major=99 ;; esac
            [ "$major" -ge 13 ] || fail "Deskie needs macOS 13 Ventura or later. This Mac has macOS $macos." ;;
  esac
  if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = "1" ]; then arch=arm64; chip="Apple Silicon"; else arch=x64; chip="Intel"; fi
  step "macOS ${macos:-?}, $chip"

  # 2. The app
  have="$(installed_version)"
  if [ -n "$have" ] && ! version_lt "$have" "$VERSION"; then
    step "Deskie $have is already installed"
    if [ -n "$(running_pids)" ]; then
      started=running
    else
      quit_running   # a Deskie from another place would keep the new one from starting
      start_app
    fi
  else
    download_verify_install
    start_app
  fi

  # 3. The Claude Code plugin
  plugin_step

  # 4. What happened
  say ""
  case "$started" in
    running) say "${B}Deskie is running.${R} Tom is in the corner of your screen." ;;
    up)      say "${B}Deskie is running.${R} Tom is in the top-right corner of your screen." ;;
    *)       say "${B}Deskie is starting.${R} Tom appears in the top-right corner in a few seconds." ;;
  esac
  if [ "$plugin" = ok ]; then
    say "Your open Claude Code chats show up on Tom's desk, and new ones join by themselves."
  fi
}

say()  { printf '%s\n' "$*"; }
step() { printf '%s\n' "  ${D}-${R} $*"; }
fail() { printf '%s\n' "" "Deskie was not installed: $*" >&2; exit 1; }

cleanup() {
  [ -n "${STAGE:-}" ] && [ -d "$STAGE" ] && rm -rf "$STAGE"
  return 0
}

# 0 if $1 < $2 (numeric x.y.z; a pre-release suffix is ignored)
version_lt() {
  _a="${1%%[-+]*}"; _b="${2%%[-+]*}"
  _i=1
  while [ "$_i" -le 3 ]; do
    _x="$(printf '%s' "$_a" | cut -d. -f"$_i")"; _y="$(printf '%s' "$_b" | cut -d. -f"$_i")"
    case "$_x" in ''|*[!0-9]*) _x=0 ;; esac
    case "$_y" in ''|*[!0-9]*) _y=0 ;; esac
    [ "$_x" -lt "$_y" ] && return 0
    [ "$_x" -gt "$_y" ] && return 1
    _i=$((_i + 1))
  done
  return 1
}

installed_version() { # nothing when there is no (readable) app
  [ -f "$APP/Contents/Info.plist" ] || return 0
  _v="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null)" || return 0
  case "$_v" in [0-9]*.[0-9]*) printf '%s' "$_v" ;; esac
}

release_url() { # $1 = file name
  printf '%s' "$RELEASE_URL" | sed -e "s|{version}|$VERSION|g" -e "s|{file}|$1|g"
}

# pids of the Deskie running from $APP (its main process; the helpers quit with it)
running_pids() {
  ps -axo pid=,command= 2>/dev/null | awk -v p="$APP/Contents/MacOS/" '{ pid = $1; sub(/^[ \t]*[0-9]+[ \t]+/, ""); if (index($0, p) == 1) print pid }'
}

# The Deskie that uses this data folder, wherever its app is (another copy in /Applications, Downloads, ...): the
# process listening on the port it wrote, if that really is a Deskie app. It holds the data folder, so a new Deskie
# would just quit while it runs.
home_pid() {
  _port=""
  [ -r "$HOME_DIR/port" ] && read -r _port < "$HOME_DIR/port"
  case "$_port" in ''|*[!0-9]*) return 0 ;; esac
  for _p in $(lsof -nP -t -iTCP:"$_port" -sTCP:LISTEN 2>/dev/null); do
    case "$(ps -o command= -p "$_p" 2>/dev/null)" in */Deskie.app/Contents/MacOS/Deskie*) printf '%s\n' "$_p" ;; esac
  done
}

deskie_pids() { { running_pids; home_pid; } | sort -u; }

# Quit a running Deskie the gentle way (SIGTERM: it quits as from its menu), then make sure.
quit_running() {
  _pids="$(deskie_pids)"
  [ -n "$_pids" ] || return 0
  step "Quitting the running Deskie"
  # shellcheck disable=SC2086
  kill -TERM $_pids 2>/dev/null
  _i=0
  while [ "$_i" -lt 20 ]; do
    _left=""
    for _p in $_pids; do kill -0 "$_p" 2>/dev/null && _left="$_left $_p"; done
    [ -n "$_left" ] || return 0
    sleep 0.5; _i=$((_i + 1))
  done
  # shellcheck disable=SC2086
  kill -KILL $_left 2>/dev/null
  sleep 0.5
  return 0
}

curl_fail() { # $1 = curl exit code, $2 = what
  if [ "$1" = 22 ]; then
    fail "Deskie $VERSION isn't on GitHub ($2 not found). Try again later."
  fi
  fail "couldn't download $2. Check your internet connection and run the installer again."
}

download_verify_install() {
  file="Deskie-$VERSION-$arch.zip"
  mkdir -p "$APPS_DIR" || fail "couldn't create $APPS_DIR."
  # Staged next to the app (same disk), so the swap below is a rename.
  STAGE="$(mktemp -d "$APPS_DIR/.deskie-install.XXXXXX")" || fail "couldn't write to $APPS_DIR."

  step "Downloading Deskie $VERSION"
  curl -fsSL --retry 2 --connect-timeout 15 -m 120 -o "$STAGE/SHA256SUMS" "$(release_url SHA256SUMS)" </dev/null || curl_fail $? "the checksum file"
  if [ -t 2 ]; then progress="-#"; else progress="-s"; fi   # the progress bar only in a terminal
  # shellcheck disable=SC2086
  curl -fL $progress --retry 2 --connect-timeout 15 -m 1800 -o "$STAGE/$file" "$(release_url "$file")" </dev/null || curl_fail $? "$file"

  expected="$(awk -v f="$file" '$2 == f || $2 == "*" f { print $1; exit }' "$STAGE/SHA256SUMS")"
  actual="$(shasum -a 256 "$STAGE/$file" | awk '{ print $1 }')"
  if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    fail "the download didn't match its checksum, so nothing was changed. Run the installer again."
  fi
  step "Checksum verified"

  mkdir "$STAGE/x" && ditto -x -k "$STAGE/$file" "$STAGE/x" 2>/dev/null || fail "couldn't unpack $file."
  [ -d "$STAGE/x/Deskie.app" ] || fail "$file has no Deskie.app inside."
  xattr -dr com.apple.quarantine "$STAGE/x/Deskie.app" 2>/dev/null

  quit_running
  if [ -e "$APP" ]; then mv "$APP" "$STAGE/old.app" || fail "couldn't replace $APP (is it open?)."; fi
  if ! mv "$STAGE/x/Deskie.app" "$APP"; then
    [ -e "$STAGE/old.app" ] && mv "$STAGE/old.app" "$APP"
    fail "couldn't move Deskie into $APPS_DIR."
  fi
  step "Installed $(pretty "$APP")"
}

pretty() { # ~ for the home folder
  case "$1" in "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;; *) printf '%s' "$1" ;; esac
}

healthy() {
  _port=""
  [ -r "$HOME_DIR/port" ] && read -r _port < "$HOME_DIR/port"
  case "$_port" in ''|*[!0-9]*) return 1 ;; esac
  curl -s -m 1 "http://127.0.0.1:$_port/health" 2>/dev/null | grep -q '"ok":true'
}

start_app() {
  started=no
  # The marker tells Deskie this `open` is not the user's own launch (which would open Settings if it already runs).
  mkdir -p "$HOME_DIR" 2>/dev/null && : > "$HOME_DIR/launcher-open"
  set -- -g
  [ -n "${DESK_BUDDY_HOME:-}" ] && set -- "$@" --env "DESK_BUDDY_HOME=$DESK_BUDDY_HOME"
  if ! "$OPEN_CMD" "$@" "$APP" --args --from-launcher --from-installer </dev/null >/dev/null 2>&1; then
    step "Couldn't start Deskie. Open it from $(pretty "$APPS_DIR")."
    return 0
  fi
  step "Starting Deskie"
  _wait="${DESK_BUDDY_HEALTH_WAIT:-15}"
  case "$_wait" in ''|*[!0-9]*) _wait=15 ;; esac
  _i=0
  while :; do
    healthy && { started=up; return 0; }
    [ "$_i" -ge "$_wait" ] && return 0
    sleep 1; _i=$((_i + 1))
  done
}

plugin_step() {
  plugin=no
  if ! command -v claude >/dev/null 2>&1; then
    say ""
    say "Couldn't find the claude command, so the Claude Code plugin isn't added yet."
    say "Inside Claude Code, run:"
    say "  /plugin marketplace add Aditya-A-G/deskie"
    say "  /plugin install deskie@deskie"
    return 0
  fi
  step "Adding the Claude Code plugin"
  if has_marketplace; then
    claude plugin marketplace update deskie </dev/null >/dev/null 2>&1   # refresh it; an old copy still works
  elif ! claude plugin marketplace add "$MARKETPLACE" </dev/null >/dev/null 2>&1 && ! has_marketplace; then
    plugin_failed; return 0
  fi
  if has_plugin; then
    claude plugin update deskie@deskie </dev/null >/dev/null 2>&1
  elif ! claude plugin install deskie@deskie </dev/null >/dev/null 2>&1 && ! has_plugin; then
    plugin_failed; return 0
  fi
  plugin=ok
}

# Already there? The JSON lists first; the plain lists if a claude without --json says no (an error, nothing printed).
has_marketplace() {
  claude plugin marketplace list --json </dev/null 2>/dev/null | grep -Eq '"name"[[:space:]]*:[[:space:]]*"deskie"' && return 0
  claude plugin marketplace list </dev/null 2>/dev/null | grep -Eq '(^|[^[:alnum:]_-])deskie([^[:alnum:]_-]|$)'
}
has_plugin() {
  claude plugin list --json </dev/null 2>/dev/null | grep -q '"deskie@deskie"' && return 0
  claude plugin list </dev/null 2>/dev/null | grep -q 'deskie@deskie'
}

plugin_failed() {
  say ""
  say "The Claude Code plugin couldn't be added automatically. Inside Claude Code, run:"
  say "  /plugin marketplace add Aditya-A-G/deskie"
  say "  /plugin install deskie@deskie"
}

main "$@"
