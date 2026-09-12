#!/usr/bin/env bash
set -euo pipefail

proto_source=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
proto_run=$(mktemp -d /tmp/proto-shape-tests.XXXXXX)
mkdir -p "$proto_run/project" "$proto_run/config" "$proto_run/cache" "$proto_run/data" "$proto_run/logs"
rsync -a --exclude=.git --exclude=.godot --exclude=dist --exclude='*.import' "$proto_source/" "$proto_run/project/"
export XDG_CONFIG_HOME="$proto_run/config"
export XDG_CACHE_HOME="$proto_run/cache"
export XDG_DATA_HOME="$proto_run/data"

run_check() {
	local name=$1 marker=$2
	shift 2
	local log="$proto_run/logs/$name.log" status=0
	godot --headless --path "$proto_run/project" "$@" >"$log" 2>&1 || status=$?
	if (( status != 0 )) || rg -q 'SCRIPT ERROR|ERROR:|WARNING:.*leaked' "$log"; then
		printf 'FAIL: %s (exit %s)\n' "$name" "$status"
		tail -80 "$log"
		printf 'Logs: %s\n' "$proto_run/logs"
		exit 1
	fi
	if [[ "$marker" != - ]] && ! rg -Fq "$marker" "$log"; then
		printf 'FAIL: %s did not finish; see %s\n' "$name" "$log"
		exit 1
	fi
	printf 'PASS: %s\n' "$name"
}

run_check import - --import

while IFS= read -r script; do
	name=$(basename "$script" .gd)
	if [[ -f "$proto_run/project/tests/$name.tscn" ]]; then
		run_check "$name" 'PASS:' --editor --quit-after 600 "res://tests/$name.tscn" -- --proto-shape-tests
	else
		run_check "$name" 'PASS:' --fixed-fps 60 --quit-after 10000 --script "$script"
	fi
done < <(cd "$proto_run/project" && rg --files tests -g 'test_*.gd' | sort)

while IFS= read -r scene; do
	run_check "smoke-$(basename "$scene" .tscn)" - --fixed-fps 60 --quit-after 300 "res://$scene"
done < <(cd "$proto_run/project" && rg --files addons -g '*.tscn' | rg '/examples?/')

printf 'All checks passed. Isolated project and logs: %s\n' "$proto_run"
