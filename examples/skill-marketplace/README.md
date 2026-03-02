# Example: Skill Marketplace

This is a real worked example from building a secure AI skill marketplace
(a clone of [skillhub.club](https://www.skillhub.club/)). It demonstrates
how the coordination documents look in practice.

## Project Overview

- **Goal**: Build a marketplace where users discover and invoke AI skills
  without accessing underlying IP
- **Tech**: FastAPI backend, React frontend, Docker sandbox, Stripe billing
- **Scale**: 22,000+ skills in catalog
- **Team**: Engineer, SRE, Designer, PM, Reviewer

## Files

- `GAP_ANALYSIS.md` - 80+ items across P0/P1/P2 priorities
- `EXECUTION_PLAN.md` - 5 sequential milestones with acceptance criteria
- `REVIEWER_FEEDBACK.md` - Per-agent steering showing the DO NOW / DO NOT pattern

## Key Takeaways

1. **GAP_ANALYSIS.md is detailed** - Each checkbox is a specific, implementable
   task. Vague items like "improve performance" don't help agents.

2. **Milestones are sequential** - M1 (auth) must complete before M2 (invocation)
   because the invoke endpoint needs auth. The plan makes this explicit.

3. **Reviewer steers proactively** - The feedback file tells each agent what to
   work on NOW and what to AVOID, preventing wasted effort.

4. **Product decisions are locked** - The gap analysis includes a "Product
   Decisions (Locked)" section so agents don't waste cycles debating choices
   that have already been made.
