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
- [Events](./sections/05-events.md)
- [Tracking](./sections/06-tracking.md)
- [Appendix A: Included Utilities](./appendix-a-included-utilities.md)
- [Appendix B: Gherkin Suites](./appendix-b-gherkin-suites.md)
- [Appendix C: OFREP](./appendix-c/index.md)
- [Appendix D: Observability](./appendix-d-observability.md)

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

Sections and subsections within the specification are marked with statuses indicating their stability level.
Functionality described in the specification graduates through these statuses with increasing stability.
Stability levels apply only to normative sections within the specification; editorial changes to examples and explanations are exempt from these constraints.
It is the responsibility of the [Technical Steering Committee](https://github.com/open-feature/community/blob/main/governance-charter.md#tsc-members) to consider and approve the graduation of documents.

Possible statuses are described below:

### Experimental

[![experimental](https://img.shields.io/static/v1?label=Status&message=experimental&color=orange)](https://github.com/open-feature/spec/tree/main/specification#experimental)

Specification sections that are marked as `Experimental` contain functionality under active development. Breaking changes are allowed and may be made without deprecation notices or warnings with minor version updates. We recommend you use these features in experimental environments and not in production.

Put simply:

> We're testing these features out. Things could change anytime.

### Hardening

[![hardening](https://img.shields.io/static/v1?label=Status&message=hardening&color=yellow)](https://github.com/open-feature/spec/tree/main/specification#hardening)

Sections marked as `Hardening` describe functionality with an emphasis on stabilizing existing requirements. Breaking changes require consensus by the [Technical Steering Committee](https://github.com/open-feature/community/blob/main/governance-charter.md#tsc-members) but may still be made with minor version updates. These features are suitable for use in production environments. Feedback is encouraged.

Put simply:

> We believe these features are ready for production use, and hope for feedback.

### Stable

[![stable](https://img.shields.io/static/v1?label=Status&message=stable&color=green)](https://github.com/open-feature/spec/tree/main/specification#stable)

Sections marked as `Stable` do not allow breaking changes without a major version update. They can be used in production with a high degree of confidence.

Put simply:

> These features are stable and battle-hardened.

> [!NOTE]  
> No explicit status = `Experimental`
