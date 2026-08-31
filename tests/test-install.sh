#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/codex-lb-test.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/bin" "$test_root/home/.codex"
if [[ "$(uname -s)" == "Darwin" ]]; then
  profile="$test_root/home/.zshrc"
else
  profile="$test_root/home/.profile"
fi

cat > "$test_root/bin/codex" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  --version) printf '%s\n' 'codex-cli test' ;;
  update|doctor|app) exit 0 ;;
esac
EOF

cat > "$test_root/bin/curl" <<'EOF'
#!/usr/bin/env bash
output=""
while (($#)); do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    -w) shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "$output" ]] || exit 2
printf '%s\n' '{"data":[{"id":"gpt-5.6-luna"},{"id":"gpt-5.6-terra"}]}' > "$output"
printf '200'
EOF

cat > "$test_root/bin/launchctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod 700 "$test_root/bin/codex" "$test_root/bin/curl" \
  "$test_root/bin/launchctl"

cat > "$test_root/home/.codex/config.toml" <<'EOF'
sandbox_mode = "workspace-write"
model = "old-model"
model_provider = "old-provider"

[projects."/tmp/example"]
trust_level = "trusted"
EOF

cat > "$profile" <<'EOF'
export EXAMPLE_SETTING=preserved
EOF

run_installer() {
  HOME="$test_root/home" \
  CODEX_HOME="$test_root/home/.codex" \
  CODEX_LB_API_KEY="test-secret" \
  PATH="$test_root/bin:$PATH" \
    bash "$repo_dir/install.sh" --no-desktop
}

run_installer
run_installer

config="$test_root/home/.codex/config.toml"
key_file="$test_root/home/.codex/codex-lb-api-key"

[[ "$(grep -c '^\[model_providers\.codex-lb\]$' "$config")" -eq 1 ]]
[[ "$(grep -c '^model = "gpt-5.6-luna"$' "$config")" -eq 1 ]]
[[ "$(grep -c '^# BEGIN CODEX-LB MANAGED$' "$profile")" -eq 1 ]]
grep -q '^sandbox_mode = "workspace-write"$' "$config"
grep -q '^\[projects\."/tmp/example"\]$' "$config"
grep -q '^requires_openai_auth = false$' "$config"
grep -q '^export EXAMPLE_SETTING=preserved$' "$profile"
[[ "$(tr -d '\r\n' < "$key_file")" == "test-secret" ]]
if [[ "$(uname -s)" == "Darwin" ]]; then
  key_mode="$(stat -f '%Lp' "$key_file")"
else
  key_mode="$(stat -c '%a' "$key_file")"
fi
[[ "$key_mode" == "600" ]]
find "$test_root/home/.codex" -maxdepth 1 -name 'config.toml.backup-*' \
  -type f | grep -q .

printf '%s\n' 'Shell installer self-test: OK'
