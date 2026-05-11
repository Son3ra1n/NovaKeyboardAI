# Agent System

This folder defines a portable "agent support layer" for iOS app and tweak projects.
The same setup can be copied to other repos (including Antigravity) with minimal changes.

## Profiles

- `appstore`: strict checks for App Store-safe repositories.
- `tweak`: checks for jailbreak/tweak repositories.

## What runs in CI

Workflows in `.github/workflows` call `scripts/agents/ci_review.sh`.
The script loads profile rules from `scripts/agents/policies/*.policy` and runs static checks.

Current checks include:

- hardcoded secret patterns
- debug logging leakage in release-facing code
- dangerous ATS settings
- private API usage (App Store profile)
- weak tweak filter patterns (Tweak profile)

## Local usage

Run checks manually:

```bash
bash scripts/agents/ci_review.sh appstore
bash scripts/agents/ci_review.sh tweak
```

## Antigravity integration

Copy these paths into Antigravity repo:

- `.github/workflows/agent-review.yml`
- `.github/workflows/agent-release-gate.yml`
- `scripts/agents/`
- `agents/`

Then set default profile in workflow env (`AGENT_PROFILE`) to `appstore` or `tweak`.
