# Coze Studio + Agent Factory Strangler Migration

## Summary

This fork should not replace Agent Factory in one large cutover. Coze Studio is
the new product shell; Agent Factory remains the governance kernel.

```text
Coze Studio
  -> agent builder
  -> workflow UI
  -> plugin UI
  -> chat/app experience

Agent Factory
  -> MCP Gateway
  -> tool risk registry
  -> policy
  -> approval
  -> audit
  -> idempotency
  -> release gate
  -> Langfuse / LiteLLM integration
```

## Non-Negotiable Boundaries

- Coze must not directly execute high-risk enterprise actions.
- Coze tools that touch external systems must call Agent Factory Gateway.
- Agent Factory `contracts/mcp-tools.yaml` remains the tool contract fact source.
- High-risk or irreversible tools must return `approval_required` before execution.
- Agent Factory audit remains the compliance fact source.
- Langfuse can be the model observability surface, but not the only audit ledger.

## Repository Strategy

Use repository separation:

```text
coze-studio-agent-factory/
  Fork of coze-dev/coze-studio.
  Keep upstream remote.
  Keep local patches in PATCH_LEDGER.md.

agent-factory/
  Existing governance repository.
  Keep Gateway, Policy, Approval, Audit, Release Gate, MCP connectors.

deploy/
  Optional deployment composition for Coze + governance + LiteLLM + Langfuse.
```

## Migration States

Do not delete old Agent Factory runtime too early.

```text
active -> frozen -> shadowed -> archived -> removed
```

Only remove old runtime code after all are true:

| Condition | Required proof |
|---|---|
| Functional parity | permission, HR, and ticket agents run through the Coze path |
| Audit parity | old and new paths produce equivalent policy/audit/approval records |
| Rollback path | a release tag can restore old runtime within 30 minutes |

## Phase 0: PoC

Goal: prove Coze can act as the product shell without weakening governance.

Deliverables:

1. Coze fork keeps `upstream` remote.
2. `PATCH_LEDGER.md` records all local deviations.
3. Agent Factory exposes:

   ```text
   POST /api/tools/invoke/{tool_name}
   ```

4. Coze imports the Agent Factory Gateway plugin.
5. One low-risk tool call succeeds through Agent Factory Gateway.
6. One high-risk tool returns `approval_required`.
7. Telegram approval executes the pending tool action from Agent Factory.
8. Langfuse trace and Agent Factory audit share correlation IDs.

Suggested tools:

```text
Low risk: knowledge.search_policy
High risk: notify.send_email
```

Go / No-Go:

| Check | Required result |
|---|---|
| Coze can call Gateway tool | pass |
| Gateway receives identity context | pass |
| high-risk tool is not executed before approval | pass |
| approval executes tool exactly once | pass |
| audit record is written | pass |
| Langfuse trace exists | pass |

## Phase 1: Tooling and HR Agent

Goal: rebuild the first real agent in Coze while preserving Agent Factory
governance.

Flow:

```text
Coze HR Agent
  -> OfferToday tool through Gateway
  -> resume scoring / assessment
  -> approval_required for candidate-facing action
  -> Telegram review
  -> notify/send action through Gateway
  -> audit + Langfuse trace
```

## Phase 2: Product Shell Migration

- New low-risk agents are created in Coze.
- High-risk agents can be designed in Coze but must use Gateway-governed tools.
- Old Agent Factory Builder / Pipeline / Registry UI is frozen.
- Agent Factory Portal shrinks into a Governance Console:
  - approvals
  - audit log
  - tool risk registry
  - release gate

## Phase 3: High-Risk Workflow Migration

- Rebuild permission and ticket workflows in Coze.
- Run old and new paths in shadow mode for at least one week.
- Compare decisions, approval triggers, blocked paths, and external action IDs.
- Freeze old runtime after parity.

## Phase 4: Cleanup

- Archive migrated specs/prompts.
- Remove old Portal builder pages.
- Remove old runtime only after rollback tag exists.
- Keep governance services and connectors.

## Implementation Rule

Start with the OpenAPI plugin path. Do not modify deep Coze workflow runtime
until the Gateway plugin, approval bridge, and trace correlation are proven.

