# OpenFeature specification (draft)

[![Roadmap](https://img.shields.io/static/v1?label=Roadmap&message=public&color=green)](https://github.com/orgs/open-feature/projects/1)
[![Contributing](https://img.shields.io/static/v1?label=Contributing&message=guide&color=blue)](https://github.com/open-feature/.github/blob/main/CONTRIBUTING.md)
[![Code of Conduct](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](https://github.com/open-feature/.github/blob/main/CODE_OF_CONDUCT.md)

This repository describes the the requirements and expectations for OpenFeature.
It also contains research that was considered while defining the spec.

> :warning: This is a draft version that includes key concepts.
> More details are coming soon!
> See [this issue](https://github.com/open-feature/spec/issues/4) for the scope of the alpha version.
> Also see the ongoing research on SDK/APIs [here](./research/existing-landscape.md)

## Design principles

- Compatibility with existing open source and commercial feature flag offerings
- Simple, understandable API
- Vendor agnostic
- First class Kubernetes support
- Native support for OpenTelemetry

### SDKs and client libraries

The project aims to provide a unified API and SDK for feature flag management in
various technology stacks. The flag evaluation logic will **not** be handled in
the OpenFeature SDK itself but provide a mechanism for interfacing with an
external evaluation engine in a vendor agnostic way.

> :warning: See the ongoing research on SDK/APIs [here](https://github.com/open-feature/sdk-research)

The OpenFeature project will include client libraries for common technology stacks including, but not limited to:

* Golang
* Java
* JavaScript/TypeScript
