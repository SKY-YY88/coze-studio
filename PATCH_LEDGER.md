# PATCH_LEDGER

This fork follows a strangler migration strategy:

```text
Coze Studio = product shell and builder experience
Agent Factory = governance kernel, tool gateway, approval, audit, and eval
```

Record every local deviation from upstream here before changing Coze Studio
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
  - Keep Coze Studio as the shell while Agent Factory remains the governance kernel.
- Upstream rebase risk:
  - Low. This is documentation plus one additive plugin product config entry.
- Rebase notes:
  - Recheck `plugin_meta.yaml` schema and plugin product loading if upstream changes plugin configuration.
  - The plugin endpoint depends on Agent Factory exposing `POST /api/tools/invoke/{tool_name}`.

