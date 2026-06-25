# PATCH_LEDGER

This fork follows a strangler migration strategy:

```text
Kyber Studio = product shell and builder experience
Agent Factory = governance kernel, tool gateway, approval, audit, and eval
```

Record every local deviation from upstream here before changing Kyber Studio
runtime code. Keep patches small and easy to rebase.

## 2026-06-12

- Area: Plugin integration / migration documentation
- Files:
  - `PATCH_LEDGER.md`
  - `docs/COZE_STRANGLER_MIGRATION.md`
  - `docs/agent-factory-gateway-plugin.md`
  - `backend/conf/plugin/pluginproduct/agent_factory_gateway.yaml`
  - `backend/conf/plugin/pluginproduct/plugin_meta.yaml`
- Reason:
  - Add the first Agent Factory Gateway plugin placeholder and migration guardrails.
  - Keep Kyber Studio as the shell while Agent Factory remains the governance kernel.
- Upstream rebase risk:
  - Low. This is documentation plus one additive plugin product config entry.
- Rebase notes:
  - Recheck `plugin_meta.yaml` schema and plugin product loading if upstream changes plugin configuration.
  - The plugin endpoint depends on Agent Factory exposing `POST /api/tools/invoke/{tool_name}`.

## 2026-06-17

- Area: Local reliability / Kyber branding
- Files:
  - `scripts/repair_es_indices.ps1`
  - `frontend/apps/coze-studio/index.html`
  - `backend/conf/admin/index.html`
- Reason:
  - Add a local repair script for missing Elasticsearch indices such as `project_draft`, which can cause the workspace list API to return HTTP 500 after incomplete local initialization.
  - Rebrand user-visible shell and admin entry points from Kyber Studio to Kyber Studio without changing upstream package names, Go module paths, or Docker service names.
- Upstream rebase risk:
  - Low. The script is additive; branding changes are limited to static HTML entry points.
- Rebase notes:
  - Re-run `scripts/repair_es_indices.ps1` after resetting Docker volumes.
  - If upstream changes frontend build output structure, update the local container hot-patch process or rebuild `coze-web` instead.
