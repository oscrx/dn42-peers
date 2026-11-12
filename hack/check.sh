#!/usr/bin/env bash
# Run the CI gate locally against a local dn42-operator checkout (until the
# operator repo is public and tagged, the workflow's go install can't work).
#
#   hack/check.sh                     # tree check of the worktree
#   hack/check.sh --base main         # PR check of HEAD against main (as a human)
#
# Registry: REGISTRY=/path/to/registry-clone, or ASN_LIST=file; default is
# the committed registry/asns.txt.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
op=${DN42_OPERATOR:-$here/../dn42-operator}
abs() { (cd "$(dirname "$1")" && echo "$(pwd)/$(basename "$1")"); }
if [ -n "${REGISTRY:-}" ]; then reg=(--registry-dir "$(abs "$REGISTRY")")
else reg=(--asn-list "$(abs "${ASN_LIST:-$here/registry/asns.txt}")"); fi
if [ "${1:-}" = "--base" ]; then
  exec go -C "$op" run ./cmd/peercheck --repo "$here" --base "$2" --author "${AUTHOR:-$(git -C "$here" config user.name)}" \
    --app-login "${APP_LOGIN:-dn42-autopeer[bot]}" "${reg[@]}"
fi
exec go -C "$op" run ./cmd/peercheck --repo "$here" --worktree "${reg[@]}"
