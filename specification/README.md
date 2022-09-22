---
id: intro
title: Introduction
description: An introduction to the OpenFeature specification.
sidebar_position: 0
---

# OpenFeature Specification

## Contents

- [Glossary](./glossary.md)
- [Types](./types.md)
- [Evaluation API](./sections/01-flag-evaluation.md)
- [Providers](./sections//02-providers.md)
- [Evaluation Context](./sections/03-evaluation-context.md)
- [Hooks](./sections/04-hooks.md)

## Conformance

### Normative Sections

The following parts of this document are normative:

- Statements under markdown H5 headings, appearing in markdown block quotes, and containing an uppercase keyword from RFC 2119.
- This conformance clause.

### Conformance Requirements and Test Assertions

Each [normative section](#normative-sections) defines a single requirement. By enumerating these normative sections, a list of test assertions can be derived.

### Compliance

An implementation is not compliant if it fails to satisfy one or more of the "MUST", "MUST NOT", "REQUIRED", "SHALL", or "SHALL NOT" requirements defined in the [normative sections](#normative-sections) of the specification. Conversely, an implementation of the specification is compliant if it satisfies all the "MUST", "MUST NOT", "REQUIRED", "SHALL", and "SHALL NOT" requirements defined in the [normative sections](#normative-sections) of the specification.

## Document Statuses

Documents and subsections within the specification are marked with statuses indicating their stability level. Functionality described in the specification graduates through these statuses with increasing stability. Stability levels apply only to normative sections within the specification; editorial changes to examples and explanations are exempt from these constraints.

Possible statuses are described below:

### Experimental

Specification documents that are marked as `Experimental` contain functionality under active development. Breaking changes are allowed and may be made without deprecation notices or warnings with minor version updates.

### Hardening

Documents marked as `Hardening` describe functionality with an emphasis on stabilizing existing requirements. Breaking changes require consensus by the [Technical Steering Committee](https://github.com/open-feature/community/blob/main/governance-charter.md#tsc-members) but may still be made with minor version updates.

### Stable

Sections marked as `Stable` do not allow breaking changes without a major version update.

### Mixed

Specification documents marked as `Mixed` contain subsections of varying statuses specified above.

NOTE: No explicit status = `Experimental`
