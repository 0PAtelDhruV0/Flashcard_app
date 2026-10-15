#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
CORE=Deckflow.swiftpm/AppModule
OUT="${TMPDIR:-/tmp}/deckflow-core-tests-$$"
trap 'rm -f "$OUT"' EXIT
swiftc "$CORE/Models.swift" "$CORE/CSVDeckService.swift" Tests/CoreTests.swift -o "$OUT"
"$OUT"
swiftc -frontend -parse "$CORE"/*.swift
printf '%s\n' 'PASS: SwiftUI source files passed Swift syntax parsing (iOS SDK compilation requires Apple tools)'