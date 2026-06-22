#!/bin/bash
# memory-selfcheck.sh: UserPromptSubmit hook.
# At the start of every user turn, inject a self-check reminder for the .agent/Memory.md § feedback rules into the system context.
# A hook cannot verify response content; the envelope reminder only increases the frequency of self-review.
# Why: remind every turn whether feedback rules that were not dogfooded are actually reflected in responses.
#
# When setting up a new repo: replace the 4 lines inside the EOF below with *this project's load-bearing feedback rules*.
# Examples: branch policy, DB push policy, context load, SessionStart signal handling.

cat <<'EOF'
[Memory self-check] Before responding, check the .agent/Memory.md § feedback rules.
- {{rule-1: one load-bearing rule for this project}}
- {{rule-2}}
- {{rule-3}}
- {{rule-4}}
If in doubt, Read .agent/Memory.md first.
EOF
