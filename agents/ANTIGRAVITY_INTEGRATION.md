# Antigravity Integration Guide

Use this checklist to enable the same agent system in Antigravity.

## 1) Copy files

Copy the following from this repository:

- `.github/workflows/agent-review.yml`
- `.github/workflows/agent-release-gate.yml`
- `scripts/agents/ci_review.sh`
- `scripts/agents/policies/appstore.policy`
- `scripts/agents/policies/tweak.policy`
- `agents/README.md`

## 2) Choose a default profile

In both workflows, set:

- `AGENT_PROFILE=appstore` for App Store projects
- `AGENT_PROFILE=tweak` for jailbreak/tweak projects

## 3) Add project-specific patterns

Edit policy files to match your own:

- bundle identifiers
- known secret key names
- denylisted imports
- tweak entry file names (`Tweak.x`, `Tweak.xm`, Logos macros)

## 4) Validate locally

Run:

```bash
bash scripts/agents/ci_review.sh appstore
```

or:

```bash
bash scripts/agents/ci_review.sh tweak
```

## 5) Enforce on PR and main

The workflows will:

- comment fail logs in CI output
- block merges when critical checks fail

If you want non-blocking mode, change workflow step:

```yaml
continue-on-error: true
```
