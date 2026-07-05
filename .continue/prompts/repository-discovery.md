---
name: repository-discovery
description: Build a concise understanding of a repository before planning or implementation.
invokable: true
---

## Purpose

Discover the repository structure, architecture, technology choices, and current maturity before making recommendations.

## Required Context

- File tree
- README and top-level docs
- Build, dependency, and configuration files
- Source layout
- Tests
- Existing conventions and style

## Process

1. Identify the repository purpose and current stage.
2. Run the filename-fidelity gate:
   - list exact inspected filenames for project, package, configuration, source, and documentation files
   - do not combine a basename from one file with an extension from another file
   - label expected but unconfirmed filenames as unconfirmed
3. Map the major directories and responsibilities.
4. Identify runtime architecture, dependencies, and integration points.
5. Identify missing or placeholder components.
6. Note risks, assumptions, and open questions.

## Output Format

- Executive Summary
- Repository Structure
- Current Architecture
- Key Workflows
- Missing Components
- Risks
- Recommended Next Steps

## Quality Checks

- Do not claim implementation exists when files are placeholders.
- Separate evidence from inference.
- Keep recommendations tied to repository facts.
- Use exact filenames from inspected file lists or file reads. Do not invent, rename, pluralize, or normalize filenames.
- Do not combine a basename from one inspected file with an extension from another inspected file.
- If an expected file is not confirmed by tools or supplied context, label it as unconfirmed instead of naming it as fact.
