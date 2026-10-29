# Consolidated test candidate

Production main remains v0.9.70 until this candidate is reviewed and merged. This candidate is based on runtime branch 42d86ae, which already contains the modernization foundation, PR #4 adapter, PR #6 projection/source controls, PR #8 co-output fixes and merged PR #10 mechanics consumption. The prepared PR #10 revert is intentionally excluded, following the owner's clarification.

The research snapshot is regenerated from a separately committed reconciliation of latest research branch 63453fe and PR #9's mechanics export. Exact final pin/checksum live in database/research-itemdb-source.json. No experimental research proposal or unreviewed coefficient is promoted by this integration.

Additional repairs: shared approval gate on executable profession/personal patch rules; reject partial character projections; latest pool policy anchor/context integrity repairs; mandatory independent research fixtures; current package/CI instructions and a manifest-only ZIP builder. Frozen TSM inputs and personal saved observations are preserved.

Pending real-client verification: addon load on supported client build; existing SavedVariables upgrade; Manual/Auto current and offline character profiles; full and partial processing values; tooltip/badge agreement; Blizzard/BetterBags/bank integrations; ATT/transmog/token behavior; capture refunds/zero outcomes. Review docs/retail-qa.md. Static tests do not establish that these checks passed.

Merge only the consolidated PR into main after review and appropriate client QA. Close superseded PRs after their included changes have been confirmed; do not reapply PR #10 or merge its revert.
