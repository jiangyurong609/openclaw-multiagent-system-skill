# Skill Marketplace - Gap Analysis

## Mission
Build a secure skill marketplace where users discover and invoke AI skills
without accessing underlying IP.

## What EXISTS Today

### Backend (FastAPI)
- [x] SQLite database with skills + install_jobs tables
- [x] Skill CRUD: GET /skills, GET /skills/{id}
- [x] Search by name/description/tags with pagination
- [x] Install queue: POST /install/{id}, GET /install
- [x] API key auth for install endpoints
- [x] Health check endpoint
- [x] 22k skills seeded from CSV

### Gateway (FastAPI)
- [x] Proxy to backend API with latency metering
- [x] API key forwarding for protected routes

### Frontend (Express + HTML)
- [x] Static file server with config injection
- [x] Basic skill grid with search and install buttons

### Infrastructure
- [x] docker-compose.yml (3 services)
- [x] K8s manifests (base + cloud overlays)
- [x] Terraform scaffolding

## What's MISSING (Priority Order)

### P0 - Critical Path

#### Authentication
- [ ] Firebase Auth integration (register, login, token verify)
- [ ] API key generation for programmatic access
- [ ] Protected routes require valid token or API key
- [ ] Role-based access: user, creator, admin

#### Secure Skill Invocation (CORE FEATURE)
- [ ] POST /v1/skills/{id}/invoke endpoint
- [ ] JSON input, structured output
- [ ] Streaming support (SSE)
- [ ] Async job support (returns job_id)
- [ ] Auth & quota enforcement
- [ ] Timeout control and idempotency key
- [ ] Error model: UNAUTHORIZED, FORBIDDEN, RATE_LIMITED, TIMEOUT, SANDBOX_ERROR

#### Docker Sandbox Runtime
- [ ] Resource-limited containers (256MB RAM, 1 CPU, 30s timeout)
- [ ] No network by default (deny-by-default egress)
- [ ] Read-only rootfs, tmpfs /tmp, seccomp profile
- [ ] Container auto-cleanup after execution
- [ ] No cross-skill memory leakage
- [ ] Invocations tracking table

#### Skill Packaging System
- [ ] skill.yaml schema (name, version, runtime, entrypoint, inputs, outputs)
- [ ] Creator upload flow: build, package, upload, validate, deploy
- [ ] Version management (draft, pending_review, published)
- [ ] Sample skills for testing (echo, text-transform, summarize)

#### Modern Frontend (React)
- [ ] Vite + React + TypeScript SPA
- [ ] Skill catalog: grid, search, filters, pagination
- [ ] Skill detail page: description, I/O schema, pricing
- [ ] Auth integration (login/register)
- [ ] Creator dashboard (publish skills, analytics, pricing)
- [ ] Dark theme, responsive, 22k skills browsable

#### Billing (Stripe)
- [ ] Per-invocation metering
- [ ] Stripe customer creation on signup
- [ ] Usage-based billing
- [ ] Revenue share: 70% creator / 30% platform
- [ ] Creator payout tracking

### P1 - Important

#### Anti-Distillation & Abuse
- [ ] Rate limiting per user/skill
- [ ] Sanitized error responses
- [ ] Log redaction
- [ ] No artifact download endpoint
- [ ] Output truncation controls

#### Observability
- [ ] Creator analytics: invocation count, revenue, latency
- [ ] Platform analytics: hot skills, abuse detection
- [ ] Structured logging

### P2 - Nice to Have

#### Governance
- [ ] Skill moderation queue
- [ ] Safety scanning on upload
- [ ] Version rollback
- [ ] Kill switch for dangerous skills

## Implementation Guidelines

### For Engineer:
- Work in marketplace-api/ directory
- Use Claude Code for implementation
- Keep SQLite for MVP (migrate to Postgres later)
- Follow existing FastAPI patterns
- Add new modules: auth.py, invoke.py, sandbox.py, billing.py

### For SRE:
- Docker sandbox module: marketplace-api/sandbox.py
- Sample skills in marketplace-api/skills/ directory
- Update docker-compose.yml with sandbox worker
- Resource limits and security are critical

### For Designer:
- React app in marketplace-web/
- Vite + React + TypeScript + Tailwind CSS
- Auth integration in frontend
- API calls through gateway

### For Reviewer:
- Security focus: sandbox escape, auth bypass, IP leakage
- No hardcoded secrets or credentials in code

## Product Decisions (Locked)
- Auth: Firebase
- Pricing: Usage-based (per invocation)
- Revenue: 70% creator / 30% platform
- Sandbox: Docker (Firecracker in Phase 2)
- Payment: Stripe
- Design: Dark theme, minimal SaaS aesthetic
- Skills: 22,000+ from seed data
