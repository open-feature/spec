---
title: Tracking
description: Specification defining tracking API
toc_max_heading_level: 4
---

# 6. Tracking

[![experimental](https://img.shields.io/static/v1?label=Status&message=experimental&color=orange)](https://github.com/open-feature/spec/tree/main/specification#experimental)

## Overview

Experimentation is a primary use case for feature flags.
In practice, this often means flags variants are assigned to users at random or in accordance to a business rule, while the impact of the assigned variant on some business objective is measured.
Vendors and custom solutions often support a _tracking_ or _goal measuring_ API to facilitate the measurement of these business objectives.

### Goals

- Develop official terminology to support consistent implementation
- Specify a flexible API widely compatible with basic vendor functionality
  - Define tracking event payload
  - Define tracking event identifier
  - Support client and server paradigms

### Non-goals

- Creating an experimentation platform
- Covering every user-tracking use case
  - Focus on A/B testing, and experimentation based on feature flags
  - Focus on "facts" not "metrics"
    - Simple point in time data, no aggregation

### Design Principles

We value the following:

- Adherence to, and compatibility with OpenFeature semantics
- Maximum compatibility and ease-of-adoption for existing solutions
- Minimum traffic and payload size
- Ease-of-use for application authors, integrators, and provider authors (in that order)
