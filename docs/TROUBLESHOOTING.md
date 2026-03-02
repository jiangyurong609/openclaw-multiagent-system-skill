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

### Agents not responding

**Symptom**: `openclaw agent --agent pm -m "..."` hangs or returns empty.

**Possible causes**:
1. **No API credentials**: Check `openclaw status` for auth issues
2. **Rate limited**: Too many concurrent agent sessions
3. **Model unavailable**: Check if the configured model is accessible

```bash
openclaw status          # overall health
openclaw channels status --probe  # channel health
```

### High API costs

**Symptom**: Unexpectedly high API bills.

**Mitigations**:
1. Increase cron intervals: `openclaw cron edit <id> --every 1h`
2. Reduce thinking level: `openclaw cron edit <id> --thinking minimal`
3. Pause when not actively developing: `openclaw-team pause`
4. Use cheaper models for PM: `openclaw cron edit <id> --model openai/gpt-4o`

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
