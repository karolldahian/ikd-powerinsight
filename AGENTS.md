# AGENTS.md

## Project

IKD PowerInsight is an auditable electrical decision-support platform.

The project uses a modular monolith with Ports & Adapters.

## Mandatory rules

- Do not invent electrical calculations, standards, articles, thresholds, sources, or results.
- Do not modify normative rules without an issue, verified source, tests, and human review.
- Do not treat OCR output as confirmed data automatically.
- Do not promote pending, uncertain, or conflicting data to confirmed status.
- Do not add dependencies without clear justification.
- Do not introduce infrastructure imports into domain or pplication.
- Keep electrical calculations deterministic, testable, and independent from frameworks.
- Keep external services behind Ports.
- Do not commit secrets, credentials, licensed standards, proprietary datasets, or private files.
- Do not commit, push, merge, tag, or publish releases without explicit human approval.
- Prefer small, traceable changes linked to an Issue.
- Use Conventional Commits.
- Run quality checks before proposing changes.

## Required checks

For backend changes:

- Ruff
- basedpyright
- Import Linter
- Pytest

For frontend changes:

- ESLint
- TypeScript/build checks as applicable

## Architecture boundaries

- domain contains pure business and electrical logic.
- ports contains abstract contracts.
- pplication orchestrates use cases.
- infrastructure contains external implementations.
- interfaces contains inbound adapters.

Dependency direction must remain inward.

## Normative content

Normative references must be traceable to approved and legally usable sources.

Do not copy or expose licensed normative text unless explicitly authorized.

## AI usage

AI may assist with OCR, retrieval, normalization, explanation, and productivity.

AI must not make final compliance decisions or silently override deterministic engineering logic.
