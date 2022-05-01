# OpenFeature Specification (Draft)

[![Roadmap](https://img.shields.io/static/v1?label=Roadmap&message=public&color=green)](https://github.com/orgs/open-feature/projects/1)
[![Contributing](https://img.shields.io/static/v1?label=Contributing&message=guide&color=blue)](https://github.com/open-feature/.github/blob/main/CONTRIBUTING.md)
[![Code of Conduct](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](https://github.com/open-feature/.github/blob/main/CODE_OF_CONDUCT.md)

This repository describes the requirements and expectations for OpenFeature.
It also contains research that was considered while defining the spec.

> :warning: This is a draft version that includes key concepts.
> More details are coming soon!
> See [this issue](https://github.com/open-feature/spec/issues/4) for the scope of the alpha version.
> Also see the ongoing research on SDK/APIs [here](./research/existing-landscape.md)
> See the [glossary](./glossary.md) for definitions of key terminology.

## Design Principles

- Compatibility with existing open source and commercial feature flag offerings
- Simple, understandable API
- Vendor agnostic
- First class Kubernetes support
- Native support for OpenTelemetry

### SDKs and Client Libraries

The project aims to provide a unified API and SDK for feature flag management in
various technology stacks. The flag evaluation logic will **not** be handled in
the OpenFeature SDK itself but provide a mechanism for interfacing with an
external evaluation engine in a vendor agnostic way.

> :warning: See the ongoing research on SDK/APIs [here](https://github.com/open-feature/sdk-research)

The OpenFeature project will include client libraries for common technology stacks including, but not limited to:

- Golang
- Java
- JavaScript/TypeScript (Node.js)

### Tooling

This specification complies with [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) and seeks to conform to the [W3C QA Framework Guildlines](https://www.w3.org/TR/qaframe-spec/).

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
