# Language Support

## Purpose

This document tracks how the Local Engineering Agent Pack should grow beyond its current .NET-centered guidance.

.NET, ASP.NET Core, APIs, and Clean Architecture remain the most mature and most validated path today. Multi-language support is now staged and evidence-gated, not a claim that every ecosystem is already equally supported.

## Current Position

| Ecosystem | Current status | Notes |
| --- | --- | --- |
| .NET / ASP.NET Core | Most mature | Existing rules, prompts, examples, and validation are strongest here. |
| Python | Optional rule pack added; generated-sample workflow validation recorded | Repository discovery, implementation planning, and code review passed generated-sample validation; real-repository and editor Apply validation remain future evidence work. |
| JavaScript / TypeScript | Optional rule pack added; generated-sample workflow validation recorded | Repository discovery, implementation planning, and code review passed generated-sample validation; real-repository and editor Apply validation remain future evidence work. |
| Java / Spring | Optional rule pack added; static generated-sample validation recorded | Needs implementation-planning, code-review, and editor/model validation before promotion. |
| Go | Optional rule pack added; static generated-sample validation recorded | Needs implementation-planning, code-review, and editor/model validation before promotion. |
| Rust | Optional rule pack added; static generated-sample validation recorded | Needs implementation-planning, code-review, and editor/model validation before promotion. |
| SQL / database projects | Optional rule pack added; static generated-sample validation recorded | Needs implementation-planning, code-review, and editor/model validation before promotion. |
| Infrastructure as Code | Optional rule pack added; static generated-sample validation recorded | Needs implementation-planning, code-review, and editor/model validation before promotion. |

## Project Detection

Use `docs/project-detection.md` as the source of truth for ecosystem signals, evidence strength, confidence labels, and unconfirmed assumptions. Language-specific guidance should not be applied until project detection has enough repository evidence.

## Milestone 15 Completion Basis

Milestone 15 is complete for the current scope because the pack now treats multi-language support as staged, evidence-gated guidance rather than .NET-only advice. .NET remains the most mature path, while Python, JavaScript/TypeScript, Java, Go, Rust, SQL, and Infrastructure as Code have optional guidance that stays outside the default `.continue/config.yaml`.

The required Python and JavaScript/TypeScript generated-sample validation is recorded in `examples/multi-language-workflow-validation.md`: repository discovery, implementation planning, and code review passed verification for both samples. `docs/project-detection.md` and `docs/language-rule-packs.md` keep language-specific recommendations gated by detected repository evidence, and broader real-repository/editor validation remains future evidence expansion.

## Shared Guidance

These standards should remain cross-language:

- Repository discovery before recommendations.
- Exact filename fidelity.
- Security review and secrets handling.
- Testability and rollback planning.
- Logging and observability expectations.
- Performance and scalability checks.
- Git hygiene and change isolation.
- Documentation updates with behavior changes.

## Language-Specific Guidance

Language-specific rules should be added only when they are useful and validated. Optional Python, TypeScript, Java, Go, Rust, SQL, and Infrastructure as Code rule packs now live in `.continue/rule-packs/` and are documented in `docs/language-rule-packs.md`. Static generated-sample validation evidence is recorded in `examples/language-rule-pack-validation.md`. They are not loaded by default from `.continue/config.yaml`.

Each language pack should define:

- Project detection signals.
- Common build and test commands.
- Dependency management expectations.
- Security-sensitive patterns.
- Testing conventions.
- Performance and reliability risks.
- Documentation expectations.
- Sample repositories or fixtures for validation.

## Guardrails

- Do not apply .NET-specific advice to non-.NET repositories.
- Do not guess the language or framework from a single file when repository evidence is incomplete.
- Do not recommend framework-specific commands until the relevant project files are inspected.
- Treat generated sample repositories as validation fixtures, not proof of production readiness.
- Keep language-specific guidance optional until it has validation evidence.

## Recommended Validation Sequence

Python and JavaScript/TypeScript are the first generated-sample workflow validation targets because they cover common personal, small-team, and open-source project shapes. Java, Go, Rust, SQL, and Infrastructure as Code now have optional static rule packs, but still need model/editor workflow validation before promotion.

Suggested sequence:

1. Confirm generated local sample repositories for each ecosystem.
2. Confirm project-detection rules for each ecosystem.
3. Keep language-specific review notes optional and out of default config.
4. Validate repository discovery, implementation planning, and code review against each sample.
5. Record sanitized evidence.
6. Promote language guidance only after the validation output is grounded and useful.
