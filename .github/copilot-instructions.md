# AutoPlanner Copilot Working Rules

## Primary Goal
Keep the repository clean, current, and easy to hand over.

## Must-Do After Changes
1. Run an appropriate quick validation for changed areas.
2. Summarize what changed and what was removed.
3. Sync to GitHub:
   - Stage relevant files.
   - Create a clear commit message.
   - Push to `main` (or the user-specified branch).

## Documentation Hygiene
- Remove outdated or contradictory docs when introducing new policy.
- Keep one source of truth for deployment policy.
- Update links immediately after file moves/deletions.
- Do not keep placeholder docs that do not exist.

## Deployment Policy
- Treat manual deployment as the default policy unless user explicitly requests CI/CD restoration.
- Keep deployment docs aligned with `DEPLOYMENT_POLICY.md` and `docs/DEPLOYMENT_SIMPLE.md`.

## Safety Constraints
- Never delete potentially useful files blindly; verify they are obsolete first.
- Never revert unrelated user changes.
- Prefer minimal, focused edits over broad refactors.
