# ADR-002 — Complete pre-launch redesign

Accepted September 14, 2026 by the owner's instruction to implement the redesign game plan. Supersedes ADR-001's visual, navigation, payout and draft deferral decisions. Pricing and purchase access remain unchanged.

One shared Expo 57 app uses Home, Schedule, Money and Settings. Existing statistics become Money / Insights. Home prioritizes unfinished work; future shifts open scheduled details. Main surfaces use off-white/charcoal, sans-serif text, teal actions and rounded 48dp controls. Warm paper and monospace are reserved for result receipts.

Earnings remain pure calculated work income. Dated receipts never increase earnings. Confirmed payout items, receipt events and allocations form a separate ledger. Unknown is null, not zero. Allocation requires matching employer and currency; excess stays unallocated. Reversal retains original events and releases allocations. Wage expectations are explicit comparable amounts, never inferred from gross wages.

Completion drafts are local and tied to the original shift revision. Completion clears its draft in the same transaction. Developer records are not erased. New ledger tables carry no fabricated opening balances. Backup format includes the full ledger.

Synthetic examples: direct 200 tips less 40 sharing = 160 earned; 60 received plus 100 later. A second 80 expectation and a 150 payment allocated 100/50 leaves 30. Pool-only: 200 collected, 200 contributed, 80 returned = 80 earned. Mixed: 200 collected, 100 contributed, 50 returned, 20 additional tip-out = 130 earned. These are engineering fixtures, not participant-validated wording.

Native accessibility, signed billing, participant timings and beta behaviour require actual device/research evidence and must not be claimed from unit tests or bundled exports. Store publishing is excluded.
