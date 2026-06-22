---
name: scope
description: Judge work size and recommend an operating unit (direct/quick/thread/phase/ADR). Use when the user asks to scope work, or when a natural-language request needs a scale/location recommendation before execution.
user-invocable: true
argument-hint: "[work description]"
---

# /scope

This skill is a thin adapter. The canonical procedure lives in the `.agent/` SSOT so the system does not depend on this skill directory.

Read and follow [`.agent/workflows/scope.md`](../../../.agent/workflows/scope.md), then produce the scope judgment as specified there. The Claude Code slash command at `.claude/commands/scope.md` points at the same SSOT.
