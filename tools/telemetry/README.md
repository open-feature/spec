# Telemetry Tooling

The [telemetry registry](../../telemetry/registry/feature_flags.yaml) references the OpenTelemetry `feature_flag.evaluation` event through an annotation-only refinement. The annotations describe OpenFeature source mappings and documentation recommendations without overriding upstream event requirements. Weaver generates the target-version statement, mapping tables, and footnotes in [Appendix D](../../specification/appendix-d-observability.md); the surrounding implementation guidance remains authored Markdown.

The resolved refinement is the authoritative OpenFeature event definition for documentation, code generation, and future SDK validation, even while it only adds annotations. Do not substitute the unchanged upstream event on the assumption that their contracts will always match. The refinement resolves its base through the manifest dependency; a separate event import is not required.

## Pinned Versions

- The Weaver CLI version is in [weaver-version.txt](./weaver-version.txt).
- The OpenTelemetry semantic-convention version and source are in [registry/manifest.yaml](../../telemetry/registry/manifest.yaml).
- Templates are maintained in this repository under [templates/markdown](./templates/markdown).

Install the matching binary from the [Weaver releases](https://github.com/open-telemetry/weaver/releases), and place `weaver` on your `PATH`. Alternatively, pass `WEAVER=/path/to/weaver` to `make`. CI installs the pinned version; local commands use the binary you provide without an additional version-checking wrapper.

The registry uses Weaver's v2 `definition/2` format. Weaver currently warns that this format is not yet stable; the tool version is pinned so format upgrades can be reviewed explicitly. The upstream feature-flag event is also a release candidate, even though its registry dependency is a tagged release.

The registry's `schema_url` identifies its initial version, `0.1.0`. It does not imply that a schema artifact is already hosted at that URL. Packaging, publishing, and defining the SDK release lifecycle remain follow-up work for a real SDK integration. Do not overwrite an externally published registry version with a different contract.

## Editing and Generating

Edit [registry/feature_flags.yaml](../../telemetry/registry/feature_flags.yaml) to change OpenFeature annotations or select additional upstream events. Only attributes needing local annotations must be referenced; the rest remain inherited. Then run from the repository root:

```shell
make telemetry-generate
make telemetry-check
```

These targets call Weaver directly, without custom wrapper scripts. Generation validates the registry, updates only the `weaver`- and `semconv`-marked sections of Appendix D, and writes [effective-events.json](../../telemetry/effective-events.json). The check validates the registry and checks both generated outputs without modifying tracked files. CI runs only on pull requests that change the telemetry registry, templates, documentation, tooling, Appendix D, Makefile, or the telemetry workflow itself.

Do not make this path-filtered workflow an unconditional required status check: GitHub can leave the check pending for unrelated pull requests when the workflow is skipped. Required enforcement would need an always-running gate that skips telemetry work for unrelated changes.

Authoring-registry resolution fetches the pinned upstream registry, so generation and freshness checks require network access. No Python runtime is needed for the telemetry workflow.

Attribute names, types, and event requirements come from the upstream event. The short `semconv refinements.events.feature_flag.evaluation(...)` markers select the resolved refinement, including inherited attributes, without embedding traversal queries in Markdown. Event-level `annotations.openfeature` supplies table headings and footnotes; attribute-level annotations supply source fields, sections, and notes. Tables follow OTel's built-in `attribute_sort`: upstream requirement level first (required, conditionally required, recommended, opt-in), then attribute key. YAML placement does not determine row order, and no numeric ordering annotations are needed. Enum attributes are displayed using their underlying value type in the mapping tables. Do not edit generated tables or footnotes directly.

Annotations do not change machine-readable event requirements or validate runtime transformations or fallback behavior in SDKs. An invalid attribute reference fails registry validation. An inherited attribute without OpenFeature annotations still appears in the Evaluation Details table, using its upstream type, requirement, and description with an empty source field and the same standard sorting. This makes new upstream attributes visible after a dependency update; review their placement and add mappings as appropriate.

### Intentional Requirement Differences

This initial migration preserves Appendix D's existing recommendations:

- `feature_flag.error.message` is conditionally required whenever evaluation fails. Upstream recommends it only when `error.type` does not sufficiently describe the error.
- `feature_flag.result.value` is recommended when a variant is available. Upstream treats it as opt-in in that case.

These differences are documentation annotations, not machine-readable event overrides, and should be reviewed separately from the tooling migration. The error-message annotation uses `recommendation` to control its displayed requirement level; otherwise the tables use the upstream event's requirement levels. The old `error.message` mapping is replaced with `feature_flag.error.message`, as introduced by upstream v1.40.0. Future SDK live-checks against this registry would enforce the upstream definitions, not these additional documentation recommendations.

### Validation Scope

`make telemetry-check` validates schema syntax, reference resolution, local documentation policies, and the freshness of Appendix D and the effective-event snapshot. It does not claim to enforce all OTel naming policies: depending on a registry is not the same as configuring those policies.

[documentation.rego](../../telemetry/registry/documentation.rego) rejects unknown annotation fields, sections, and recommendations; invalid or duplicate footnotes; undefined footnote references; and invalid table headings or annotation text. Attributes without OpenFeature annotations remain valid and inherited.

The generated snapshot records the effective event's attributes, requirements, conditions, enum members, descriptions, notes, annotations, and upstream dependency version. It intentionally excludes filesystem provenance paths for reproducibility. Review this snapshot in dependency-update PRs even if the Markdown tables did not change: local documentation can mask an upstream description or condition change. Weaver v0.28.0's `registry diff` does not report all field-level refinement changes and is not a substitute for this review.

### Future SDK Validation

Weaver v0.28.0's live-check indexes `registry.events`, not `refinements.events`. Checking the authoring registry directly can therefore report `missing_event` for a valid evaluation. Adding an unchanged import would validate the upstream definition rather than the authoritative refinement. Runtime validation must consume the effective OpenFeature contract. Runtime export, packaging, and SDK integration are outside the scope of this documentation workflow.

Live-check cannot evaluate English conditional requirements, and semantic-convention events are log-based events, not span events. Error/success scenarios, variant/value availability, enum transformations, metadata fallback, and redaction still require SDK-specific behavioral tests. Documentation-only recommendations are not automatically enforced.

### Code Generation Compatibility

Annotation-only refinements contain all inherited attributes and can supply SDK constants generation. However, Weaver v0.28.0's standard v2 `semconv_attributes` and `semconv_events` helpers read `registry.attributes` and `registry.events`, not `refinements.events`. Applied directly to this refinement-only registry, those helpers return empty collections. This is the known upstream gap tracked in [Weaver #1623](https://github.com/open-telemetry/weaver/issues/1623), which proposes optionally including refinements in signal filters.

A codegen target reading the authoring registry should select resolved refinements directly using an ordinary template filter:

```jq
{
  events: .refinements.events,
  attributes: (
    [.refinements.events[].attributes[]]
    | unique_by(.key)
  )
}
```

This selects the effective OpenFeature definitions, including inherited attributes, without changing the registry's structure or requirements. Attribute keys are deduplicated for name constants; signal-specific requirements and notes must be read from `events[].attributes`, not from the deduplicated attribute list. Adding actual requirement or attribute changes to a refinement later will therefore be visible to codegen rather than bypassed through an unchanged upstream import.

Language-specific codegen templates and SDK publication are not provided by this workflow. Existing SDK templates may require adaptation to the v2 refinement model.

## Dependency Updates

Renovate proposes updates to the OTel dependency and Weaver version; they are not automerged. For each update:

1. Keep the dependency's `schema_url` version and `registry_path` tag consistent.
2. Review upstream feature-flag changes, deprecations, requirements, and new attributes alongside the documentation mappings. Retained documentation recommendations can differ from changed upstream guidance.
3. If upgrading Weaver, install the new pinned version and review the setup action and template compatibility as well, including the codegen helper behavior described above.
4. Run generation and freshness checks. Inspect the effective-event snapshot as well as the documentation diff, and update Appendix D's history as needed. Its stated target version is generated from the dependency manifest.
5. Identify SDK migration work before merging behavioral changes.
