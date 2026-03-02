# Troubleshooting

## Common Issues

### "gateway timeout" when running cron

**Symptom**: `Error: gateway timeout after 30000ms`

**Fix**: The gateway might not be running or the cron timeout is too short.

```bash
# Check gateway
openclaw daemon status

# If not running
openclaw daemon start

# If running but timeout is too short, increase it
openclaw cron edit <id> --timeout-seconds 900
```

### Agents not producing code

**Symptom**: Cron cycles complete but no new files appear.

**Possible causes**:
1. **No Claude Code available**: Agents delegate coding via `claude` CLI.
   Verify it's installed: `which claude`
2. **GAP_ANALYSIS.md is empty**: Agents need a filled-in gap analysis to
   know what to build. Run `openclaw-team kickoff` to have PM fill it in.
3. **REVIEWER_FEEDBACK.md says "wait"**: Agents follow reviewer's steering.
   Check if the reviewer told them to wait.

### Agents working on wrong milestone

**Symptom**: Engineer is building M3 when M1 isn't done.

**Fix**: Edit `REVIEWER_FEEDBACK.md` directly:

```markdown
## Engineer
**DO NOW:** STOP. Go back to M1. Implement auth module.
**DO NOT:** Work on anything from M2, M3, or M4.
```

The engineer will read this at the start of the next cycle.

### Stale team.json

**Symptom**: `manage.sh` reports errors about missing cron IDs.

**Fix**: If crons were deleted manually, re-bootstrap:

```bash
openclaw-team stop my-project      # clean up any remaining crons
openclaw-team new my-project ~/Projects/my-project "description"
```

### Authentication errors (401 / invalid x-api-key)

**Symptom**: `authentication_error: invalid x-api-key` or `HTTP 401`

**Cause**: Anthropic session tokens (`sk-ant-sid01-...`) expire every ~5 hours.

**Fix**: Sync Claude Code's fresh token to OpenClaw agents:

```bash
# Claude Code stores its OAuth token here:
cat ~/.claude/.credentials.json | python3 -c "
import json, sys
d = json.load(sys.stdin)['claudeAiOauth']
print(f'Token expires: {d[\"expiresAt\"]}')
"

# Sync to all agents (run the sync-tokens.sh script)
openclaw-team sync-tokens
```

Or re-authenticate Claude Code: `claude login`

**Long-term fix**: Set up ACP integration so Claude Code handles its own auth.
See [ARCHITECTURE.md](ARCHITECTURE.md#acp-integration).

### API rate limits

**Symptom**: `API rate limit reached. Please try again later.` or
`FailoverError` across all providers.

**Fix**: Add fallback model providers so agents fail over:

```bash
# Set primary model
openclaw models set openai-codex/gpt-5.3-codex

# Add fallbacks (tried in order)
openclaw models fallbacks add google/gemini-3-flash-preview
openclaw models fallbacks add anthropic/claude-sonnet-4-6

# Verify chain
openclaw models list
```

To add Google Gemini (free tier):
1. Get API key from https://aistudio.google.com/apikey
2. `openclaw models auth paste-token --provider google`
3. `openclaw models fallbacks add google/gemini-3-flash-preview`

### Telegram delivery failures

**Symptom**: `No delivery target resolved for channel "telegram". Set delivery.to.`

**Cause**: Cron jobs have `--announce` but no `--to` destination.

**Fix**: Set the Telegram chat ID on each cron:

```bash
# Find your chat ID
python3 -c "import json; d=json.load(open('$HOME/.openclaw/openclaw.json')); print(d['channels']['telegram']['accounts']['default']['allowFrom'])"

# Fix each cron
openclaw cron edit <cron-id> --announce --channel telegram --to <chat-id> --best-effort-deliver
```

### Agents not responding

**Symptom**: `openclaw agent --agent pm -m "..."` hangs or returns empty.

**Possible causes**:
1. **No API credentials**: Check `openclaw status` for auth issues
2. **Rate limited**: Too many concurrent agent sessions -- add fallback models
3. **Model unavailable**: Check if the configured model is accessible
4. **Token expired**: Session tokens expire, see "Authentication errors" above

```bash
openclaw status          # overall health
openclaw channels status --probe  # channel health
openclaw models list     # verify all models show Auth=yes
```

### High API costs

**Symptom**: Unexpectedly high API bills.

**Context**: With default settings, expect ~500k-800k tokens per worker per
cycle (two-level delegation: OpenClaw agent reasons + Claude Code writes code).
PM/Reviewer use ~30k-100k per cycle (read-only coordination).

**Mitigations**:
1. **Slow down cycles**: PM/Reviewer every 45m, workers every 1h:
   `openclaw cron edit <id> --every 1h`
2. **Cheaper models for non-coding agents**: PM and Reviewer don't write code:
   `openclaw cron edit <id> --model openai-codex/gpt-5.3-codex`
3. **Shorter prompts**: Reduce cron message length to save input tokens
4. **Pause when idle**: `openclaw-team pause`
5. **Add free tier fallback**: Google Gemini free tier as fallback provider

### Cron runs pile up

**Symptom**: Multiple cron runs queue up, agents fall behind.

**Fix**: Cron runs are independent. If runs take longer than the interval,
they'll overlap. Increase interval or timeout:

```bash
openclaw cron edit <id> --every 45m --timeout-seconds 900
```

## Debugging

### View cron run history
```bash
openclaw cron runs --id <cron-id>
```

### View gateway logs
```bash
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

### Test a single agent manually
```bash
openclaw agent --agent pm \
  -m "Quick status check -- what milestone are we on?" \
  --timeout 60 \
  --verbose on
```

### Check what agents see
Read the same files agents read each cycle:
```bash
cat ~/Projects/my-app/REVIEWER_FEEDBACK.md
cat ~/Projects/my-app/EXECUTION_PLAN.md
cat ~/Projects/my-app/GAP_ANALYSIS.md
```
