# Execution Plan & Milestones

**Owner:** PM Agent

## Milestone 1: Foundation
**Goal:** Backend authenticates users and serves 22k skills via API
**Acceptance Criteria:**
- [ ] Firebase Auth integrated (register, login, token verify)
- [ ] All 22k skills queryable via GET /skills with search + pagination
- [ ] API key generation for programmatic access
- [ ] Protected routes require valid Firebase token or API key
- [ ] Health endpoint confirms auth + DB are operational

**Assigned:**
- Engineer: Firebase auth module (auth.py), update app.py
- SRE: Verify docker-compose works with auth env vars

**Status:** IN PROGRESS
**Blockers:** None

---

## Milestone 2: Secure Invocation
**Goal:** Users invoke skills via API and get structured output without seeing internals
**Acceptance Criteria:**
- [ ] POST /v1/skills/{id}/invoke works end-to-end
- [ ] Docker sandbox executes skill code with resource limits
- [ ] Input via JSON, output via JSON -- no IP leakage
- [ ] Invocations logged in DB
- [ ] At least 2 sample skills work (echo + text-transform)
- [ ] Errors are sanitized

**Assigned:**
- SRE: Docker sandbox module, sample skills, resource limits
- Engineer: invoke.py endpoint, invocations table
- Reviewer: Security audit of sandbox

**Status:** NOT STARTED (blocked by M1)
**Blockers:** M1 must complete first

---

## Milestone 3: Marketplace Frontend (parallel with M2)
**Goal:** Modern React UI browsing 22k skills
**Acceptance Criteria:**
- [ ] Vite + React + TypeScript scaffolded
- [ ] Skill catalog page: grid, search, tags, pagination
- [ ] Skill detail page: description, pricing placeholder
- [ ] Firebase auth: login, register
- [ ] Navbar with search and auth state
- [ ] Dark theme, responsive
- [ ] Connects to gateway API

**Assigned:**
- Designer: All frontend implementation
- Engineer: Ensure API returns data frontend needs

**Status:** NOT STARTED (can start parallel)
**Blockers:** None

---

## Milestone 4: Billing & Creator Tools
**Goal:** Per-invocation billing with Stripe, creators set pricing
**Acceptance Criteria:**
- [ ] Stripe customer created on signup
- [ ] Per-invocation metering events recorded
- [ ] Pricing per skill (creator-set, default free)
- [ ] 70/30 revenue split calculated
- [ ] Creator dashboard API
- [ ] Skill upload endpoint

**Assigned:**
- Engineer: billing.py, Stripe integration, creator endpoints

**Status:** NOT STARTED (blocked by M2)
**Blockers:** M2 must complete first

---

## Milestone 5: Polish & Deploy
**Goal:** Production-ready deployment
**Acceptance Criteria:**
- [ ] Docker compose runs full stack
- [ ] All frontend pages connected to backend
- [ ] Invoke works from UI
- [ ] Rate limiting in place
- [ ] README with setup instructions

**Assigned:**
- SRE: Docker compose, deployment
- Designer: UI polish
- Reviewer: Full security review

**Status:** NOT STARTED (blocked by M3 + M4)

---

## Agent Assignments

| Agent | Current Task | Milestone | Priority |
|-------|-------------|-----------|----------|
| Engineer | Firebase auth module | M1 | P0 |
| SRE | Docker sandbox prep | M2 (prep) | P0 |
| Designer | React SPA scaffold | M3 | P0 |
| Reviewer | Review all | ALL | Ongoing |
| PM | Track milestones | ALL | Ongoing |

## Coordination Rules
1. Sequential: M1 -> M2 -> M4 -> M5 (M3 runs parallel)
2. Completion policy: milestone is COMPLETE when all acceptance criteria checked. PM force-advances after 2+ cycles code-complete with no P0 blockers.
3. Reviewer feedback is advisory for P1/P2. Only P0 (system can't run) blocks. Reviewer must APPROVE when criteria are met.
4. PM updates this file every cycle
5. Agents update GAP_ANALYSIS.md checkboxes when items complete

## Progress Log

### Cycle 1
- Engineer: dispatched to work on Firebase auth
- SRE: dispatched to prep Docker sandbox module
- Designer: dispatched to scaffold React frontend
- All agents running first work cycle
