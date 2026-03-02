# Reviewer Steering Instructions

**Last updated:** <!-- Reviewer updates each cycle -->
**Reviewer:** Code Review Agent

---

## Milestone Gate Status

<!-- For each active milestone, write APPROVED or BLOCKER with reason -->
<!-- APPROVED = acceptance criteria met, agents proceed to next milestone -->
<!-- BLOCKER = P0 issue (system cannot run), must state the single fix needed -->
<!-- P1/P2 issues are noted below but do NOT block approval -->

---

## Engineer
**DO NOW:** <!-- Specific task from current milestone -->
**DO NOT:** <!-- What to avoid, common mistakes -->

---

## SRE
**DO NOW:** <!-- Specific task from current milestone -->
**DO NOT:** <!-- What to avoid -->

---

## Designer
**DO NOW:** <!-- Specific task from current milestone -->
**DO NOT:** <!-- What to avoid -->

---

## Overall Assessment
- <!-- Security issues found? (P0 = blocks, P1/P2 = advisory) -->
- <!-- Are agents on the right milestone? -->
- <!-- Code quality concerns? -->

## Approval Rules (Reviewer MUST follow)
1. If ALL acceptance criteria for a milestone are checked, write **APPROVED** and tell agents to start the next milestone.
2. Only block on P0 issues (system cannot run). P1/P2 are noted but do not block.
3. A milestone code-complete for 2+ cycles MUST be approved or state the single remaining fix.
4. When writing a BLOCKER, you MUST assign it to a specific agent (e.g. "Engineer: fix X"). Unassigned blockers are ignored by workers.
5. Your job is to steer and unblock. Ship progress, not perfection.
