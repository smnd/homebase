#!/usr/bin/env zsh
# shellcheck disable=all
#
# glab-git — a drop-in `git` that authenticates to GitLab with a Personal
#            Access Token, on a machine that may have nothing installed yet.
#
# Every git subcommand works exactly as it does with git, same arguments:
#   glab-git clone <project-path|url> [dest]   glab-git commit -m "msg"
#   glab-git pull [args...]                    glab-git status
#   glab-git push [args...]                    glab-git log --oneline -5
#   ...anything else git accepts, passed through verbatim.
#
# Make plain `git` work everywhere:   alias git='glab-git'
#
# Self-bootstrapping: installs curl, git and glab if they are missing.
# A token is required only for commands that touch the network (clone, fetch,
# pull, push, ls-remote, submodule, remote); local commands like commit, status
# and log run without one.
#
# The token is never written to .git/config, never placed in the remote URL,
# and never appears on a command line (so it stays out of `ps` and history).
# It reaches git through an ephemeral credential helper that releases it only
# to $GITLAB_HOST.
#
# Own subcommands (everything else goes to git):
#   glab-git bootstrap    install curl + git + glab
#   glab-git doctor       show what is installed, where, and token status
#   glab-git auth         verify the token against the GitLab API
#   glab-git glab <args>  run glab, pre-authenticated (e.g. glab-git glab mr list)
#
# Token resolution order:
#   1. $GITLAB_TOKEN
#   2. $GITLAB_TOKEN_FILE  (a file containing only the token)
#   3. macOS Keychain:  security find-generic-password -s "$GITLAB_KEYCHAIN_SERVICE"
#
# Environment:
#   GITLAB_TOKEN, GITLAB_TOKEN_FILE, GITLAB_HOST (default gitlab.com),
#   GITLAB_KEYCHAIN_SERVICE, GLAB_GIT_PREFIX (install dir, default ~/.local)
#
# One-time Keychain setup (macOS):
#   security add-generic-password -a "$USER" -s gitlab-pat-gitlab.com -w
#
set -euo pipefail

GITLAB_HOST="${GITLAB_HOST:-gitlab.com}"
GITLAB_KEYCHAIN_SERVICE="${GITLAB_KEYCHAIN_SERVICE:-gitlab-pat-${GITLAB_HOST}}"
PREFIX="${GLAB_GIT_PREFIX:-$HOME/.local}"
BINDIR="$PREFIX/bin"
GLAB_PROJECT_ID=34675721   # gitlab-org/cli

die()  { printf 'glab-git: %s\n' "$*" >&2; exit 1; }
note() { printf 'glab-git: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- bootstrap --

SUDO=""
init_sudo() {
  [[ $EUID -eq 0 ]] && return 0
  have sudo && { SUDO="sudo"; return 0; }
  return 1
}

pkg_manager() {
  local m
  for m in apt-get dnf yum apk pacman zypper brew; do have "$m" && { echo "$m"; return; }; done
  echo none
}

pkg_install() {
  local pm; pm="$(pkg_manager)"
  case "$pm" in
    brew)    brew install "$@" ;;
    apt-get) init_sudo || return 1; $SUDO apt-get update -qq && $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
    dnf)     init_sudo || return 1; $SUDO dnf install -y -q "$@" ;;
    yum)     init_sudo || return 1; $SUDO yum install -y -q "$@" ;;
    apk)     init_sudo || return 1; $SUDO apk add --no-cache "$@" ;;
    pacman)  init_sudo || return 1; $SUDO pacman -Sy --noconfirm --needed "$@" ;;
    zypper)  init_sudo || return 1; $SUDO zypper --non-interactive install "$@" ;;
    *)       return 1 ;;
  esac
}

ensure_curl() {
  have curl && return 0
  note "curl is missing — installing"
  pkg_install curl ca-certificates 2>/dev/null || pkg_install curl || true
  have curl || die "could not install curl automatically; install it and re-run"
}

ensure_git() {
  have git && return 0
  note "git is missing — installing"
  if [[ "$(uname -s)" == "Darwin" ]] && ! have brew; then
    note "macOS without Homebrew: git ships with the Xcode Command Line Tools"
    xcode-select --install 2>/dev/null || true
    die "accept the Xcode Command Line Tools dialog, let it finish, then re-run"
  fi
  pkg_install git || die "could not install git automatically; install it and re-run"
  have git || die "git still not on PATH after install"
}

os_arch() {
  local os arch
  case "$(uname -s)" in
    Darwin) os=darwin ;;
    Linux)  os=linux ;;
    *)      die "unsupported OS $(uname -s) — install glab from https://gitlab.com/gitlab-org/cli/-/releases" ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64)  arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    i386|i686)     arch=386 ;;
    armv7l|armv6l) arch=armv6 ;;
    *)             die "unsupported architecture $(uname -m)" ;;
  esac
  printf '%s %s' "$os" "$arch"
}

sha256_of() {
  if   have sha256sum; then sha256sum "$1" | awk '{print $1}'
  elif have shasum;    then shasum -a 256 "$1" | awk '{print $1}'
  else echo ""; fi
}

ensure_glab() {
  have glab && return 0
  note "glab is missing — installing"
  if have brew; then brew install glab && have glab && return 0; fi

  ensure_curl
  local os arch ver tag url tmp sum want
  read -r os arch <<<"$(os_arch)"

  tag="$(curl -fsSL --max-time 30 \
        "https://${GITLAB_HOST}/api/v4/projects/${GLAB_PROJECT_ID}/releases/permalink/latest" \
        | tr ',' '\n' | grep -oE '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4)"
  [[ -n "$tag" ]] || die "could not resolve the latest glab release from ${GITLAB_HOST}"
  ver="${tag#v}"

  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
  url="https://${GITLAB_HOST}/gitlab-org/cli/-/releases/${tag}/downloads/glab_${ver}_${os}_${arch}.tar.gz"
  note "downloading glab ${ver} (${os}/${arch})"
  curl -fsSL --max-time 180 -o "$tmp/glab.tar.gz" "$url" || die "download failed: $url"

  # Verify against the release's published checksums before executing anything.
  want="$(curl -fsSL --max-time 30 \
         "https://${GITLAB_HOST}/gitlab-org/cli/-/releases/${tag}/downloads/checksums.txt" 2>/dev/null \
         | awk -v f="glab_${ver}_${os}_${arch}.tar.gz" '$2==f {print $1}')"
  sum="$(sha256_of "$tmp/glab.tar.gz")"
  if [[ -n "$want" && -n "$sum" ]]; then
    [[ "$want" == "$sum" ]] || die "checksum mismatch for glab ${ver} — refusing to install"
    note "checksum verified"
  else
    note "WARNING: could not verify the checksum (missing checksums.txt or sha256 tool)"
  fi

  tar -xzf "$tmp/glab.tar.gz" -C "$tmp"
  [[ -f "$tmp/bin/glab" ]] || die "unexpected archive layout — no bin/glab"
  mkdir -p "$BINDIR"
  install -m 0755 "$tmp/bin/glab" "$BINDIR/glab"
  export PATH="$BINDIR:$PATH"
  have glab || die "installed to $BINDIR/glab but it is not on PATH"
  note "installed glab to $BINDIR/glab"
  case ":$PATH:" in
    *":$BINDIR:"*) ;;
    *) note "add to your shell profile:  export PATH=\"$BINDIR:\$PATH\"" ;;
  esac
}

# --------------------------------------------------------------------- auth --

TOKEN_LOADED=0
load_token() { # load_token [required]
  local required="${1:-}"
  if [[ $TOKEN_LOADED -eq 0 ]]; then
    if [[ -z "${GITLAB_TOKEN:-}" && -n "${GITLAB_TOKEN_FILE:-}" && -r "${GITLAB_TOKEN_FILE}" ]]; then
      GITLAB_TOKEN="$(<"${GITLAB_TOKEN_FILE}")"
    fi
    if [[ -z "${GITLAB_TOKEN:-}" ]] && have security; then
      GITLAB_TOKEN="$(security find-generic-password -s "${GITLAB_KEYCHAIN_SERVICE}" -w 2>/dev/null || true)"
    fi
    GITLAB_TOKEN="${GITLAB_TOKEN%%$'\n'*}"
    TOKEN_LOADED=1
  fi
  if [[ -z "${GITLAB_TOKEN:-}" ]]; then
    [[ "$required" == required ]] && die "no token: set GITLAB_TOKEN, GITLAB_TOKEN_FILE, or add it to the Keychain under service '${GITLAB_KEYCHAIN_SERVICE}'"
    return 1
  fi
  # glab reads both natively, so no interactive `glab auth login` is needed.
  export GITLAB_TOKEN GITLAB_HOST
  return 0
}

# Credential helper, inlined as a git config value. $GITLAB_TOKEN and $GITLAB_HOST
# are expanded by the helper's own shell at call time, so neither is ever an
# argument to git. The host check keeps the token from reaching a foreign remote
# (a hostile submodule URL, say).
CRED_HELPER='!f() { [ "$1" = get ] || exit 0; h=""; while IFS="=" read -r k v; do [ -z "$k" ] && break; [ "$k" = host ] && h="$v"; done; [ "$h" = "$GITLAB_HOST" ] || exit 0; printf "username=oauth2\npassword=%s\n" "$GITLAB_TOKEN"; }; f'

# A global `url.<ssh-base>.insteadOf = https://<host>/` rewrite silently turns
# our HTTPS URL into SSH, so the PAT is never consulted and the failure looks
# like a permissions problem. Such a rewrite cannot be overridden with -c (the
# rules are additive, longest-match-wins), and dropping the global config
# outright would lose user.name/user.email. So: copy the global config and
# remove only the rewrites that target our host.
REWRITE_TMP=""
cleanup_rewrite() { [[ -n "$REWRITE_TMP" ]] && rm -f "$REWRITE_TMP"; return 0; }
# Re-exit with the status the shell already had: a wrapper for git must pass
# git's exit code through untouched, or every `&&` chain and CI step misreads it.
trap 'rc=$?; cleanup_rewrite; exit $rc' EXIT

neutralize_url_rewrite() {
  local probe="https://${GITLAB_HOST}/__probe__.git" effective src key val
  effective="$(git ls-remote --get-url "$probe" 2>/dev/null || echo "$probe")"
  [[ "$effective" == "$probe" ]] && return 0   # no rewrite in play

  src="$(git config --global --list --show-origin 2>/dev/null | head -1 | cut -d"$(printf '\t')" -f1)"
  src="${src#file:}"
  if [[ -z "$src" || ! -r "$src" ]]; then
    note "a URL rewrite redirects https://${GITLAB_HOST}/ to '${effective}' and the global config could not be read — the token may not be used"
    return 0
  fi

  REWRITE_TMP="$(mktemp)"
  cat "$src" >"$REWRITE_TMP"
  while read -r key val; do
    [[ -z "$key" ]] && continue
    # Drop only rewrites whose source URL is our host and whose target is not HTTPS.
    if [[ "$val" == "https://${GITLAB_HOST}/"* || "$val" == "http://${GITLAB_HOST}/"* ]] \
       && [[ "$key" != url.https://* ]]; then
      # git matches value patterns with POSIX *extended* regex: `?` not `\?`.
      git config --file "$REWRITE_TMP" --unset-all "$key" "^https?://${GITLAB_HOST}/" 2>/dev/null || true
    fi
  done < <(git config --global --get-regexp '^url\..*\.(insteadof|pushinsteadof)$' 2>/dev/null)

  export GIT_CONFIG_GLOBAL="$REWRITE_TMP"
  if [[ "$(git ls-remote --get-url "$probe" 2>/dev/null)" == "$probe" ]]; then
    note "ignoring a git URL rewrite (${src}) that would send https://${GITLAB_HOST}/ over SSH; your other global settings are untouched"
  else
    note "WARNING: https://${GITLAB_HOST}/ is still being rewritten to '${effective}' (check system or repo-local config) — the token may not be used"
  fi
}

# The empty first helper clears any inherited helper (osxkeychain, store, ...)
# so the PAT is never cached to disk behind your back.
git_auth() {
  if [[ -n "${GITLAB_TOKEN:-}" ]]; then
    neutralize_url_rewrite
    git -c credential.helper= \
        -c "credential.https://${GITLAB_HOST}.helper=${CRED_HELPER}" \
        -c "credential.https://${GITLAB_HOST}.username=oauth2" \
        "$@"
  else
    git "$@"
  fi
}

# Commands that always talk to a remote, so a token must be present. Kept
# deliberately narrow: `remote -v` and `submodule status` are local, and a
# wrapper that demanded a token for them would not be a drop-in. Anything not
# listed still gets the credential helper when a token happens to be available.
needs_token() {
  case "$1" in
    clone|fetch|pull|push|ls-remote) return 0 ;;
    *) return 1 ;;
  esac
}

# Expand a bare `group/subgroup/project` into a full HTTPS URL, leaving real
# URLs, flags and existing local paths untouched. Only applied to `clone`.
expand_clone_args() {
  CLONE_ARGS=()
  local expanded=0 a
  for a in "$@"; do
    if [[ $expanded -eq 0 && "$a" != -* && "$a" != *://* && "$a" != *@*:* && "$a" == */* && ! -e "$a" ]]; then
      CLONE_ARGS+=("https://${GITLAB_HOST}/${a%.git}.git"); expanded=1
    else
      CLONE_ARGS+=("$a")
    fi
  done
}

warn_ssh_remote() { # a PAT cannot authenticate an SSH remote; say so early
  local url
  url="$(git remote get-url "${GIT_REMOTE:-origin}" 2>/dev/null)" || return 0
  case "$url" in
    git@*|ssh://*) note "remote '${GIT_REMOTE:-origin}' is SSH ($url) — the PAT will not be used; git will fall back to your SSH key" ;;
    *"@${GITLAB_HOST}/"*) note "remote URL has credentials embedded in it; consider: git remote set-url ${GIT_REMOTE:-origin} https://${GITLAB_HOST}/${url#*"@${GITLAB_HOST}/"}" ;;
  esac
}

# ----------------------------------------------------------- own subcommands --

cmd_bootstrap() {
  ensure_curl; ensure_git; ensure_glab
  note "ready: $(git --version), $(glab --version 2>/dev/null | head -1)"
}

cmd_auth() {
  ensure_curl; load_token required
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "https://${GITLAB_HOST}/api/v4/user")"
  case "$code" in
    200) note "token OK for https://${GITLAB_HOST}" ;;
    401) die "token rejected (401) — expired or revoked" ;;
    403) die "token valid but forbidden (403) — check its scopes (need read_repository / write_repository)" ;;
    *)   die "unexpected response ${code} from https://${GITLAB_HOST}/api/v4/user" ;;
  esac
}

cmd_doctor() {
  load_token || true
  printf 'host        : %s\n' "$GITLAB_HOST"
  printf 'install dir : %s\n' "$BINDIR"
  printf 'pkg manager : %s\n' "$(pkg_manager)"
  local c
  for c in curl git glab tar; do
    if have "$c"; then printf '%-12s: %s\n' "$c" "$(command -v "$c")"
    else               printf '%-12s: MISSING (run: glab-git bootstrap)\n' "$c"; fi
  done
  if [[ -n "${GITLAB_TOKEN:-}" ]]; then printf 'token       : present (%s chars)\n' "${#GITLAB_TOKEN}"
  else                                  printf 'token       : NOT FOUND\n'; fi
}

cmd_glab() {
  ensure_glab; load_token required
  [[ $# -gt 0 ]] || die "usage: glab-git glab <glab args>   (e.g. glab-git glab mr list)"
  glab "$@"
}

# --------------------------------------------------------------------- main --

main() {
  local sub="${1:-}"
  case "$sub" in
    bootstrap)         shift; cmd_bootstrap "$@"; return ;;
    doctor)            shift; cmd_doctor    "$@"; return ;;
    auth)              shift; cmd_auth      "$@"; return ;;
    glab)              shift; cmd_glab      "$@"; return ;;
    -h|--help|help|"") awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "$0"; return ;;
  esac

  # Everything else is git, verbatim.
  ensure_git
  if needs_token "$sub"; then load_token required; else load_token || true; fi

  if [[ "$sub" == clone ]]; then
    shift; expand_clone_args "$@"
    git_auth clone "${CLONE_ARGS[@]}"
    return
  fi

  if needs_token "$sub" && git rev-parse --git-dir >/dev/null 2>&1; then
    warn_ssh_remote
  fi
  git_auth "$@"
}

main "$@"
