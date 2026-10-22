# AI declaration

Usage:

This repository makes use of AI code generation using the following tools: Claude-Code[Claude Sonnet 5.5].

This repository makes use of AI in-line editing using the following tools: none.

This repository makes use of AI code-review using the following tools: Claude-Code[Claude Sonnet 5.5].

## What the AI did

| Area | Tool | Notes |
| --- | --- | --- |
| Generation | Claude-Code[Claude Sonnet 5.5] | `Dockerfile`, `compose.yml`, `.dockerignore` changes, `mkdocs.yml`, everything in `docs/`, and the README declaration |
| Review | Claude-Code[Claude Sonnet 5.5] | Checked the stack against the lab requirements and ran `automark.sh` to verify the result |

The application source under `src/` was provided with the lab and was not modified.

Commits that contain AI-generated code carry an `Assisted-by:` trailer, for example:

```
Assisted-by: Claude-Code[Claude Sonnet 5.5]
```

**Student:** Victor Hyginus (2849537)
