# Parity Exclusions Matrix

Tracks explicit out-of-scope items for Circular -> Linear parity to prevent scope creep.

| Item | Why Excluded | Owner | Revisit Condition |
| --- | --- | --- | --- |
| Issue subscriptions (My Issues: Subscribed) | Requires subscription model + notification/event wiring not yet implemented in current single-tenant scope | Product + Backend | Revisit when subscription data model and notification events are added without violating single-tenant constraints |
| Inbox parity with external integrations | Depends on third-party provider integrations not present in this repo | Product | Revisit when integration strategy is approved and provider clients exist |
| External VCS attachment parity (deep GitHub/GitLab sync) | Depends on non-existing third-party integration pipeline | Product + Integrations | Revisit once external integration layer and auth scopes are implemented |
| Multi-workspace/org behaviors from Linear | Out of scope by explicit project constraint (single-tenant only) | Project Owner | Revisit only if non-negotiable constraints change |
