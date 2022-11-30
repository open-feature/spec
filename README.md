# OpenFeature Specification

[![Roadmap](https://img.shields.io/static/v1?label=Roadmap&message=public&color=green)](https://github.com/orgs/open-feature/projects/1) [![Contributing](https://img.shields.io/static/v1?label=Contributing&message=guide&color=blue)](https://github.com/open-feature/.github/blob/main/CONTRIBUTING.md) [![Code of Conduct](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](https://github.com/open-feature/.github/blob/main/CODE_OF_CONDUCT.md)

This repository describes the requirements and expectations for OpenFeature.

> :warning: Ongoing research can be found in the [research repo](https://github.com/open-feature/research). For definitions of key terminology, see the [glossary](./specification/glossary.md).

## Design Principles

- Compatibility with existing feature flag offerings
- Simple, understandable APIs
- Vendor agnosticism
- Language agnosticism
- Low/no dependency
- Extensibility

### SDKs and Client Libraries

The project aims to provide a unified API and SDK for feature flag management in various technology stacks.
The OpenFeature SDK provides a mechanism for interfacing
with an external evaluation engine in a vendor agnostic way;
it does **not** itself handle the flag evaluation logic.

The OpenFeature project will include client libraries for common technology stacks including, but not limited to:

- Golang
- Java
- JavaScript/TypeScript (Node.js)

### Tooling

This specification complies with [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) and seeks to conform to the [W3C QA Framework Guidelines](https://www.w3.org/TR/qaframe-spec/).

In accordance with this, some basic tooling (donated graciously by [Diego Hurtado](https://github.com/ocelotl)) has been employed to parse the specification and output a JSON structure of concise requirements, highlighting the particular `RFC 2119` verb in question.

To parse the specification, simply type `make`. Please review the generated JSON files, which will appear as siblings to any of the markdown files in the `/specification` folder.

### Style Guide

- Use code blocks for examples.
  - Code blocks should be pseudocode, not any particular language, but should be vaguely "Java-esque".
- Use conditional requirements for requirements that only apply in particular situations, such as particular languages or runtimes.
- Use "sentence case" enclosed in ticks (\`) when identifying entities outside of code blocks (ie: `evaluation details` instead of `EvaluationDetails`).
- Do not place line breaks into sentences, keep sentences to a single line for easier review.
- String literals appearing outside of code blocks should be enclosed in both ticks (\`) and double-quotes (") (ie: `"PARSE_ERROR"`).
- Use "Title Case" for all titles.
- Use the imperative mood and passive voice.
