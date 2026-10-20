#!/usr/bin/env bash
# The architecture rules from AGENTS.md, as greps. Run at step-4-tested (main).
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
fail=0

chk() { if grep -rqE "$2" $1; then echo "✗ $3"; grep -rnE "$2" $1 | sed 's/^/    /'; fail=1; else echo "✓ $3"; fi; }

chk "stable-date/Features"                          "URLSession|JSONDecoder|URL\("   "Views/ViewModels never touch networking"
chk "stable-date/Features/Swipe/SwipeViewModel.swift" "import SwiftUI"                "ViewModel doesn't import SwiftUI"
chk "stable-date/Features/Swipe/SwipeViewModel.swift" "LiveHorseService"              "ViewModel doesn't name the real service"
chk "stable-date/Features/Swipe/SwipeViewModel.swift" "var isLoading|errorMessage"    "ViewModel has no parallel state flags"
chk "stable-date/Services stable-date/Models"       "import SwiftUI|ViewModel"       "Services/Models don't know about UI"

n=$(grep -rl "LiveHorseService()" stable-date | wc -l | tr -d ' ')
if [[ "$n" == "1" ]] && grep -q "LiveHorseService()" stable-date/App/StableDateApp.swift; then
  echo "✓ only StableDateApp constructs LiveHorseService"
else
  echo "✗ LiveHorseService constructed in $n files"; grep -rn "LiveHorseService()" stable-date | sed 's/^/    /'; fail=1
fi

# Long capitalised literals in Features, ignoring SF Symbol names, previews and comments.
lit=$(grep -rnE '"[A-Z][a-z].{12,}"' stable-date/Features | grep -v "systemImage" | grep -v "#Preview" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//')
if [[ -z "$lit" ]]; then
  echo "✓ no long string literals in Views (all in Copy)"
else
  echo "⚠ possible user-facing literals outside Copy.swift:"; echo "$lit" | sed 's/^/    /'
fi
exit $fail
