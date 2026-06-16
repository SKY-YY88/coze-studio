# Agent Factory Gateway Plugin

## Purpose

This plugin connects Coze Studio agents and workflows to Agent Factory tools
without bypassing enterprise governance.

Coze calls one Gateway endpoint:

```text
POST https://factory.applehappy.net/api/tools/invoke/{tool_name}
```

For local PoC, choose the server URL based on how Coze Studio is running:

| Coze Studio runtime | Plugin `servers[0].url` |
|---|---|
| Native process on the same Windows host | `http://127.0.0.1:8200` |
| Docker container on Windows/macOS | `http://host.docker.internal:8200` |
| Public test/prod Gateway | `https://factory.applehappy.net` |

The checked-in PoC config currently uses:

```text
http://host.docker.internal:8200
```

because Coze Studio is commonly started from Docker during local evaluation.

Agent Factory then handles:

- tool contract lookup
- identity mapping
- risk and policy decision
- approval interception
- idempotency
- audit
- MCP Gateway invocation
- Langfuse / trace correlation

## Request Contract

Path:

```text
tool_name: string
```

Headers:

```text
Authorization: Bearer <internal service token>
X-Agent-Factory-Workspace: default
X-Agent-Factory-User: coze-plugin
X-Agent-Factory-Conversation-Id: optional
X-Agent-Factory-Trace-Id: optional
```

Body:

```json
{
  "query": "CRM admin access policy",
  "target_system": "crm",
  "permission_type": "admin",
  "dry_run": true,
  "idempotency_key": "optional-stable-key"
}
```

Coze Studio's plugin editor may drop object-typed parameters that do not
declare nested fields. For this PoC, the checked-in OpenAPI uses flat
tool-specific fields instead of a single `arguments` object. Agent Factory's
Gateway adapter still accepts both forms:

- wrapped: `{"arguments": {...}}`
- flat: `{"query": "...", "target_system": "..."}`

## Response Contract

Allowed:

```json
{
  "decision": "allowed",
  "tool_name": "knowledge.search_policy",
  "result": {},
  "audit_id": "audit_xxx",
  "trace_id": "trace_xxx"
}
```

Approval required:

```json
{
  "decision": "approval_required",
  "approval_id": "appr_xxx",
  "message": "This action requires human approval.",
  "status_url": "https://factory.applehappy.net/approvals/appr_xxx",
  "audit_id": "audit_xxx",
  "trace_id": "trace_xxx"
}
```

Blocked:

```json
{
  "decision": "blocked",
  "message": "This tool call is blocked by policy.",
  "audit_id": "audit_xxx",
  "trace_id": "trace_xxx"
}
```

## Coze Behavior

If `decision == "approval_required"`, Coze should not retry or simulate the
external action. It should tell the user:

```text
This action requires approval. I submitted it to the reviewer.
```

The real execution is owned by Agent Factory after approval.

## First Test

1. Start Agent Factory Gateway on the host and verify from `coze-server`:

   ```bash
   docker exec coze-server sh -lc "curl -sS http://host.docker.internal:8200/health"
   ```

2. Create/login to a Coze workspace at `http://127.0.0.1:8888`.
3. Import the Agent Factory Gateway plugin.
   If the full OpenAPI import path is slow in the local Docker image, use the
   same flow as the UI: create plugin metadata first, then add/update the tool
   API with `POST /api/plugin_api/register_plugin_meta`,
   `POST /api/plugin_api/create_api`, and `POST /api/plugin_api/update_api`.
4. Call:

   ```text
   knowledge.search_policy
   ```

5. Confirm Agent Factory audit contains the tool call.
6. Call a high-risk write tool such as:

   ```text
   notify.send_email
   ```

7. Confirm Coze receives `approval_required` and no email is sent before approval.
