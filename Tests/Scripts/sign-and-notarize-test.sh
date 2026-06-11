#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/tmp"
printf '#!/usr/bin/env bash\nexit 86\n' > "$TEST_ROOT/bin/openssl"
chmod +x "$TEST_ROOT/bin/openssl"

set +e
PATH="$TEST_ROOT/bin:$PATH" \
TMPDIR="$TEST_ROOT/tmp" \
APP_STORE_CONNECT_API_KEY_P8='-----BEGIN EC PRIVATE KEY-----\ninvalid\n-----END EC PRIVATE KEY-----' \
APP_STORE_CONNECT_KEY_ID='test-key' \
APP_STORE_CONNECT_ISSUER_ID='test-issuer' \
  "$ROOT/Scripts/sign-and-notarize.sh" >/dev/null 2>&1
status=$?
set -e

if [[ "$status" -ne 86 ]]; then
  echo "Expected openssl failure status 86, got $status" >&2
  exit 1
fi

if find "$TEST_ROOT/tmp" -mindepth 1 -print -quit | grep -q .; then
  echo "Notarization temporary files remained after key conversion failure" >&2
  exit 1
fi

echo "sign-and-notarize cleanup test passed"
