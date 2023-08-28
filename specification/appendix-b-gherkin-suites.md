---
title: Appendix A: End-to-End Tests
description: A Set of End-to-End Tests for Validating OpenFeature Implementations
sidebar_position: 5
---

# Appendix B: Gherkin Suites

This section contains a set of language-agnostic end-to-end tests (defined in gherkin).
These tests can be used to validate the behavior of an OpenFeature implementation.
"Features" (test suites) can be used in conjunction with a cucumber test-runner for the language in question.

## Evaluation Feature

The [evaluation feature](./assets/gherkin/evaluation.feature) contains tests for the basic functionality of the [Evaluation API](./sections/01-flag-evaluation.md).