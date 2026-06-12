# Agent Factory Gateway Plugin

## Purpose

This plugin connects Coze Studio agents and workflows to Agent Factory tools
without bypassing enterprise governance.

Coze calls one Gateway endpoint:

```text
POST https://factory.applehappy.net/api/tools/invoke/{tool_name}
```

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
  "arguments": {
    "query": "CRM admin access policy"
  },
  "identity": {
    "user_id": "coze-plugin",
    "role": "operator"
  },
  "dry_run": true,
  "idempotency_key": "optional-stable-key"
}
```

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

1. Import the Agent Factory Gateway plugin.
2. Call:

   ```text
   knowledge.search_policy
   ```

3. Confirm Agent Factory audit contains the tool call.
4. Call a high-risk write tool such as:

   ```text
   notify.send_email
   ```

5. Confirm Coze receives `approval_required` and no email is sent before approval.

