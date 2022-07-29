---
id: intro
title: Intro
description: An intro to the OpenFeature specification.
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

| Status               | Explanation                   |
| -------------------- | ----------------------------- |
| No Explicit "Status" | Equivalent to Experimental.   |
| Experimental         | Breaking changes are allowed. |
