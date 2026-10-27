# Telemetry Tooling

Generate the mapping tables, footnotes, and target-version statement in [Appendix D](../../specification/appendix-d-observability.md) from the [telemetry registry](../../telemetry/registry/feature_flags.yaml).

## Requirements

Install the version listed in [weaver-version.txt](./weaver-version.txt) from the [Weaver releases](https://github.com/open-telemetry/weaver/releases), and place `weaver` on your `PATH`. Alternatively, pass `WEAVER=/path/to/weaver` to `make`.

Network access is required to resolve the pinned OpenTelemetry dependency. The registry uses Weaver's experimental v2 format, which can produce format-stability warnings.

## Usage

Edit the registry definitions or templates, then run from the repository root:

```shell
make telemetry-generate
make telemetry-check
```

`telemetry-generate` validates the registry and updates Appendix D's marked sections and the effective-event snapshot. `telemetry-check` validates the registry and documentation annotations, then checks that both generated outputs are current without modifying tracked files.

Do not edit generated tables, footnotes, or the snapshot directly. SDK code generation, runtime validation, and registry publication are not included in this workflow.

## Files

- [registry/manifest.yaml](../../telemetry/registry/manifest.yaml): upstream dependency and version pin.
- [registry/feature_flags.yaml](../../telemetry/registry/feature_flags.yaml): event refinement and OpenFeature source mappings, notes, and footnotes.
- [registry/documentation.rego](../../telemetry/registry/documentation.rego): validation rules for documentation annotations.
- [effective-events.json](../../telemetry/effective-events.json): generated snapshot of the full effective event definition.
- [templates](./templates): Markdown and snapshot templates.

## Dependency Updates

Renovate proposes updates to the OpenTelemetry dependency and Weaver version; they are not automerged. Keep the dependency's `schema_url` version and `registry_path` tag consistent, regenerate, and review both Appendix D and the effective-event snapshot. The snapshot includes upstream conditions, notes, and enum values that may not appear in the tables.

For Weaver upgrades, install the new pinned binary and verify template compatibility. Update Appendix D's history when adopting semantic-convention changes.
