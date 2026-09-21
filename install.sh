#!/usr/bin/env bash
set -euo pipefail

DEFAULT_ENDPOINT="https://cdx.2brain.pro/backend-api/codex"
DEFAULT_MODELS_URL="https://cdx.2brain.pro/v1/models"
DEFAULT_MODEL="gpt-5.6-luna"
MANAGED_START="# BEGIN CODEX-LB MANAGED"
MANAGED_END="# END CODEX-LB MANAGED"

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Options:
  --endpoint URL       Codex-LB Codex endpoint
  --models-url URL     Authenticated model-list endpoint
  --model MODEL        Default model (default: gpt-5.6-luna)
  --dry-run            Detect installations without changing anything
  --no-desktop         Do not launch or install the Desktop app
  -h, --help           Show this help

Set CODEX_LB_API_KEY in the environment for unattended private use.
EOF
}

backup_file() {
  local path="$1"
  local backup
  [[ -f "$path" ]] || return 0
  backup="${path}.backup-$(date +%Y%m%d-%H%M%S)"
  [[ -e "$backup" ]] && backup="${backup}-$$"
  cp -p "$path" "$backup"
  printf 'Backup: %s\n' "$backup"
}

find_codex_cli() {
  local candidate
  if command -v codex >/dev/null 2>&1; then
    command -v codex
    return
  fi
  for candidate in \
    "$HOME/.local/bin/codex" \
    "$HOME/.codex/packages/standalone/current/bin/codex" \
    "$HOME/.npm-global/bin/codex" \
    "/opt/homebrew/bin/codex" \
    "/usr/local/bin/codex"; do
    [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return; }
  done
}

find_macos_desktop() {
  local app
  for app in \
    "/Applications/ChatGPT.app" \
    "/Applications/Codex.app" \
    "$HOME/Applications/ChatGPT.app" \
    "$HOME/Applications/Codex.app"; do
    [[ -d "$app" && -f "$app/Contents/Info.plist" ]] && { printf '%s\n' "$app"; return; }
  done
}

wait_for_macos_desktop() {
  local path
  for _ in {1..30}; do
    path="$(find_macos_desktop || true)"
    if [[ -n "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
    sleep 2
  done
  return 1
}

ensure_macos_desktop() {
  [[ -n "$desktop_path" ]] && return 0
  [[ -n "$codex_bin" ]] || die "Codex Desktop is not installed and Codex CLI is unavailable to install it"
  printf 'Opening the official Codex Desktop installer...\n'
  "$codex_bin" app "$PWD" || die "The official Codex Desktop installer could not be started"
  desktop_path="$(wait_for_macos_desktop || true)"
  [[ -n "$desktop_path" ]] || die "Codex Desktop installation was not confirmed; finish the installer and rerun this command"
  printf 'Codex Desktop installed: %s\n' "$desktop_path"
}

desktop_version() {
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$1/Contents/Info.plist" 2>/dev/null || printf 'unknown\n'
}

install_cli() {
  command -v curl >/dev/null 2>&1 || die "curl is required to install Codex CLI"
  printf 'Installing the official Codex CLI...\n'
  CODEX_NON_INTERACTIVE=1 curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
}

update_cli() {
  local path="$1"
  printf 'Codex CLI before update: '
  "$path" --version
  if ! "$path" update; then
    printf 'Self-update was unavailable; running the official installer.\n'
    install_cli
  fi
}

read_hidden_key() {
  [[ -r /dev/tty ]] || die "Interactive terminal is required; set CODEX_LB_API_KEY for unattended use"
  printf 'Enter Codex-LB API key (hidden): ' >/dev/tty
  IFS= read -r -s CODEX_LB_API_KEY </dev/tty || true
  printf '\n' >/dev/tty
  export CODEX_LB_API_KEY
}

endpoint="$DEFAULT_ENDPOINT"
models_url="$DEFAULT_MODELS_URL"
model="$DEFAULT_MODEL"
dry_run=0
no_desktop=0

while (($#)); do
  case "$1" in
    --endpoint) (($# >= 2)) || die "--endpoint requires a value"; endpoint="$2"; shift 2 ;;
    --models-url) (($# >= 2)) || die "--models-url requires a value"; models_url="$2"; shift 2 ;;
    --model) (($# >= 2)) || die "--model requires a value"; model="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    --no-desktop) no_desktop=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ "$endpoint" =~ ^https://[A-Za-z0-9._:/-]+$ ]] || die "Invalid HTTPS endpoint"
[[ "$models_url" =~ ^https://[A-Za-z0-9._:/-]+$ ]] || die "Invalid HTTPS models URL"
[[ "$model" =~ ^[A-Za-z0-9._-]+$ ]] || die "Invalid model name"

os_name="$(uname -s)"
[[ "$os_name" == "Darwin" || "$os_name" == "Linux" ]] || die "Supported systems: macOS and Linux"

codex_bin="$(find_codex_cli || true)"
desktop_path=""
if [[ "$os_name" == "Darwin" ]]; then
  desktop_path="$(find_macos_desktop || true)"
fi

printf 'System: %s %s\n' "$os_name" "$(uname -m)"
if [[ -n "$desktop_path" ]]; then
  printf 'Codex Desktop: %s (version %s)\n' "$desktop_path" "$(desktop_version "$desktop_path")"
  codesign --verify --deep --strict "$desktop_path" >/dev/null 2>&1 \
    && printf 'Codex Desktop signature: OK\n' \
    || printf 'Warning: Codex Desktop signature validation failed\n' >&2
else
  printf 'Codex Desktop: not found\n'
fi
if [[ -n "$codex_bin" ]]; then
  printf 'Codex CLI: %s (%s)\n' "$codex_bin" "$("$codex_bin" --version)"
else
  printf 'Codex CLI: not found\n'
fi

if ((dry_run)); then
  printf 'Dry run complete; no changes were made.\n'
  exit 0
fi

if [[ -n "$codex_bin" ]]; then
  update_cli "$codex_bin"
elif [[ -z "$desktop_path" || "$os_name" == "Linux" ]]; then
  install_cli
fi
codex_bin="$(find_codex_cli || true)"

if [[ "$os_name" != "Darwin" || -z "$desktop_path" ]]; then
  [[ -n "$codex_bin" ]] || die "Codex CLI installation was not confirmed"
fi

if [[ "$os_name" == "Darwin" && "$no_desktop" -eq 0 ]]; then
  ensure_macos_desktop
fi

codex_home="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$codex_home"
umask 077
key_file="$codex_home/codex-lb-api-key"

if [[ -z "${CODEX_LB_API_KEY:-}" && -s "$key_file" ]]; then
  existing_key="$(tr -d '\r\n' < "$key_file")"
  if [[ -r /dev/tty ]]; then
    printf 'Saved Codex-LB key found. Reuse it? [Y/n]: ' >/dev/tty
    IFS= read -r answer </dev/tty || answer=""
  else
    answer="y"
  fi
  case "$answer" in n|N|no|NO) ;; *) CODEX_LB_API_KEY="$existing_key"; export CODEX_LB_API_KEY ;; esac
fi
[[ -n "${CODEX_LB_API_KEY:-}" ]] || read_hidden_key
[[ "$CODEX_LB_API_KEY" != *$'\n'* && "$CODEX_LB_API_KEY" != *$'\r'* ]] || die "API key contains a newline"

models_tmp="$(mktemp "${TMPDIR:-/tmp}/codex-lb-models.XXXXXX")"
trap 'rm -f "$models_tmp"' EXIT
http_code="$(curl -sS -o "$models_tmp" -w '%{http_code}' --connect-timeout 10 --max-time 30 \
  -H "Authorization: Bearer $CODEX_LB_API_KEY" "$models_url" || true)"
case "$http_code" in
  2[0-9][0-9]) ;;
  401|403) die "Codex-LB rejected the API key (HTTP $http_code)" ;;
  *) die "Codex-LB model check failed (HTTP ${http_code:-network error})" ;;
esac
grep -Eq '"data"[[:space:]]*:[[:space:]]*\[' "$models_tmp" \
  || die "Codex-LB model catalog has no data array"
printf 'Codex-LB key and model catalog: OK\n'

key_tmp="$(mktemp "$codex_home/.codex-lb-api-key.XXXXXX")"
printf '%s\n' "$CODEX_LB_API_KEY" > "$key_tmp"
chmod 600 "$key_tmp"
mv -f "$key_tmp" "$key_file"

config_path="$codex_home/config.toml"
backup_file "$config_path"
config_clean="$(mktemp "$codex_home/.config.clean.XXXXXX")"
if [[ -f "$config_path" ]]; then
  awk -v start="$MANAGED_START" -v end="$MANAGED_END" '
    $0 == start { managed = 1; next }
    $0 == end { managed = 0; next }
    managed { next }
    /^[[:space:]]*\[model_providers\.codex-lb\][[:space:]]*$/ { provider = 1; next }
    provider && /^[[:space:]]*\[/ { provider = 0 }
    provider { next }
    /^[[:space:]]*\[/ { in_top = 0 }
    NR == 1 { in_top = 1 }
    in_top && /^[[:space:]]*(model|review_model|model_provider|model_catalog_json)[[:space:]]*=/ { next }
    { print }
  ' "$config_path" > "$config_clean"
else
  : > "$config_clean"
fi

config_new="$(mktemp "$codex_home/.config.new.XXXXXX")"
{
  printf 'model = "%s"\n' "$model"
  printf 'review_model = "%s"\n' "$model"
  printf 'model_provider = "codex-lb"\n'
  cat "$config_clean"
  printf '\n%s\n' "$MANAGED_START"
  printf '[model_providers.codex-lb]\n'
  printf 'name = "openai"\n'
  printf 'base_url = "%s"\n' "${endpoint%/}"
  printf 'wire_api = "responses"\n'
  printf 'supports_websockets = true\n'
  printf 'requires_openai_auth = false\n'
  printf 'env_key = "CODEX_LB_API_KEY"\n'
  printf '%s\n' "$MANAGED_END"
} > "$config_new"
rm -f "$config_clean"
mv -f "$config_new" "$config_path"
chmod 600 "$config_path"

rc_path="$HOME/.profile"
[[ "$os_name" == "Darwin" ]] && rc_path="$HOME/.zshrc"
backup_file "$rc_path"
rc_tmp="$(mktemp "${TMPDIR:-/tmp}/codex-lb-rc.XXXXXX")"
if [[ -f "$rc_path" ]]; then
  awk -v start="$MANAGED_START" -v end="$MANAGED_END" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$rc_path" > "$rc_tmp"
fi
{
  printf '\n%s\n' "$MANAGED_START"
  # The command substitution is intentionally written to the shell profile.
  # shellcheck disable=SC2016
  printf 'export CODEX_LB_API_KEY="$(tr -d '\''\\r\\n'\'' < %q)"\n' "$key_file"
  printf '%s\n' "$MANAGED_END"
} >> "$rc_tmp"
mv -f "$rc_tmp" "$rc_path"

if [[ "$os_name" == "Darwin" ]]; then
  launchctl setenv CODEX_LB_API_KEY "$CODEX_LB_API_KEY"
  helper="$codex_home/set-codex-lb-env.sh"
  cat > "$helper" <<EOF
#!/bin/sh
key_file='$key_file'
[ -r "\$key_file" ] || exit 0
exec /bin/launchctl setenv CODEX_LB_API_KEY "\$(/usr/bin/tr -d '\\r\\n' < "\$key_file")"
EOF
  chmod 700 "$helper"
  launch_agents="$HOME/Library/LaunchAgents"
  mkdir -p "$launch_agents"
  plist="$launch_agents/pro.2brain.codex-lb-env.plist"
  backup_file "$plist"
  helper_xml="$(printf '%s' "$helper" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>pro.2brain.codex-lb-env</string>
  <key>ProgramArguments</key><array><string>$helper_xml</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
EOF
  chmod 600 "$plist"
  launchctl bootout "gui/$(id -u)" "$plist" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$plist" >/dev/null 2>&1 || printf 'Warning: LaunchAgent will load at next login.\n' >&2
fi

if [[ -n "$codex_bin" ]]; then
  printf 'Codex CLI after setup: '
  "$codex_bin" --version
  "$codex_bin" doctor >/dev/null 2>&1 || printf 'Warning: codex doctor reported diagnostics; run it manually for details.\n' >&2
fi

if [[ "$os_name" == "Darwin" && "$no_desktop" -eq 0 ]]; then
  open "$desktop_path" || die "Codex Desktop could not be opened"
fi

if ((no_desktop)); then
  printf 'Setup complete. Codex-LB configured; Desktop installation and launch were skipped.\n'
else
  printf 'Setup complete. Fully restart Codex Desktop so it inherits the new provider environment.\n'
fi
