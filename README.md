<!-- markdownlint-disable MD033 -->
<!-- x-hide-in-docs-start -->
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/open-feature/community/0e23508c163a6a1ac8c0ced3e4bd78faafe627c7/assets/logo/horizontal/white/openfeature-horizontal-white.svg" />
    <img align="center" alt="OpenFeature Logo" src="https://raw.githubusercontent.com/open-feature/community/0e23508c163a6a1ac8c0ced3e4bd78faafe627c7/assets/logo/horizontal/black/openfeature-horizontal-black.svg" />
  </picture>
</p>

<h2 align="center">OpenFeature Specification</h2>

<!-- x-hide-in-docs-end -->
<!-- The 'github-badges' class is used in the docs -->
<p align="center" class="github-badges">
  <a href="https://github.com/orgs/open-feature/projects/1">
    <img alt="Roadmap" src="https://img.shields.io/static/v1?label=Roadmap&message=public&color=green" />
  </a>
  <a href="https://github.com/open-feature/.github/blob/main/CONTRIBUTING.md">
    <img alt="Contributing" src="https://img.shields.io/static/v1?label=Contributing&message=guide&color=blue" />
  </a>
  <a href="https://cloud-native.slack.com/archives/C0344AANLA1">
    <img alt="Slack" src="https://img.shields.io/badge/slack-%40cncf%2Fopenfeature-brightgreen?style=flat&logo=slack"/>
  </a>
  <a href="https://bestpractices.coreinfrastructure.org/projects/6601">
    <img alt="CII Best Practices" src="https://bestpractices.coreinfrastructure.org/projects/6601/badge" />
  </a>
</p>
<!-- x-hide-in-docs-start -->

[OpenFeature](https://openfeature.dev) is an open specification that provides a vendor-agnostic, community-driven API for feature flagging that works with your favorite feature flag management tool or in-house solution.

This repository describes the requirements and expectations for OpenFeature.

## Design Principles

The OpenFeature specification must be designed with:

- compatibility with existing feature flag offerings.
- simple, understandable APIs.
- vendor agnosticism.
- language agnosticism.
- low/no dependency.
- extensibility.

### SDKs and Client Libraries

The project aims to provide a unified API and SDK feature flag evaluation across popular technology stacks.
The OpenFeature SDK provides a mechanism for interfacing
with an external evaluation engine in a vendor agnostic way;
it does **not** itself handle the flag evaluation logic.

An up-to-date SDK compatibility overview can be found [here](https://openfeature.dev/docs/reference/sdks/sdk-compatibility).

### Tooling

This specification complies with [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) and seeks to conform to the [W3C QA Framework Guidelines](https://www.w3.org/TR/qaframe-spec/).

In accordance with this, some basic tooling (donated graciously by [Diego Hurtado](https://github.com/ocelotl)) has been employed to parse the specification and output a JSON structure of concise requirements, highlighting the particular `RFC 2119` verb in question.

To parse the specification, simply type `make`.
Please review the generated JSON files, which will appear as siblings to any of the markdown files in the `/specification` folder.

### Style Guide

- Use code blocks for examples.
  - Code blocks should be pseudocode, not any particular language, but should be vaguely "Java-esque".
- Use conditional requirements for requirements that only apply in particular situations, such as particular languages or runtimes.
- Use "sentence case" enclosed in ticks (\`) when identifying entities outside of code blocks (ie: `evaluation details` instead of `EvaluationDetails`).
- Do not place line breaks into sentences, keep sentences to a single line for easier review.
- String literals appearing outside of code blocks should be enclosed in both ticks (\`) and double-quotes (") (ie: `"PARSE_ERROR"`).
- Use "Title Case" for all titles.
- Use the imperative mood and passive voice.
