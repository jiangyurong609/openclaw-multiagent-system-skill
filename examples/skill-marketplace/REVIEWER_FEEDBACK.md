# Reviewer Steering Instructions

**Reviewer:** Code Review Agent

---

## Engineer
**DO NOW:** Implement Firebase auth in marketplace-api/auth.py
- Install firebase-admin SDK (add to requirements.txt)
- Create auth.py: Firebase token verification, user registration, API key generation
- Mount auth routes in app.py
- Add auth middleware for protected endpoints
- Test that GET /skills remains public, POST /install requires auth

**DO NOT:**
- Skip to M2 (invoke) before auth is working
- Use custom JWT -- must be Firebase
- Hardcode any Firebase credentials (use env vars)

---

## SRE
**DO NOW:** Start building sandbox.py module while Engineer works on M1
- Create marketplace-api/sandbox.py with DockerSandbox class
- Create marketplace-api/skills/echo/ sample skill (skill.yaml + main.py + Dockerfile)
- Test Docker container resource limits locally
- Do NOT wire into API yet (needs auth from M1 first)

**DO NOT:**
- Implement the invoke endpoint yet (needs auth)
- Skip resource limits -- they are security critical

---

## Designer
**DO NOW:** Scaffold the React app
- Init Vite + React + TypeScript in marketplace-web/
- Set up Tailwind CSS
- Build SkillCatalog page (grid, search, pagination)
- Connect to existing GET /api/skills endpoint
- Keep Express server.js for serving built assets

**DO NOT:**
- Build auth pages until Firebase config is available from Engineer
- Build invoke UI until M2 is done
- Build billing UI until M4 is done

---

## Overall Assessment
- No security issues to report (no new code yet)
- Agents should focus on their assigned milestone
- Next review in 20 minutes
