# GitHub Workflow

## Solo Dev Flow (Trunk-Based)

Work directly on `main`, tag to release.

### Day-to-Day

1. Commit to `main` (or short-lived branches for bigger changes)
2. CI runs automatically on every push (format, analyze, tests on stable + beta)

### Releasing

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md` with new version section
3. Commit and push
4. Tag and push:
   ```bash
   git tag v0.1.11 && git push --tags
   ```
5. Automation handles the rest:
   - Version consistency check (tag must match pubspec.yaml)
   - Format + analyze + tests must pass
   - GitHub Release created with changelog notes
   - Published to pub.dev

### What Runs Automatically

| Trigger | Workflow | What it does |
|---------|----------|-------------|
| Push/PR to main | Test | Format, analyze, unit tests (stable + beta) |
| Push/PR to main | Static Analysis | `dart analyze --fatal-warnings` (also weekly) |
| Push v* tag | Test | Format, analyze, unit tests |
| Push v* tag | Release | Version check, validate, create GitHub Release |
| Push v* tag | Publish | Version check, validate, publish to pub.dev |
| Dependabot PR | Auto-merge | Auto squash-merge after CI passes |
| Weekly (Mon) | Dependabot | Grouped dependency update PRs |
| Weekly (Sun) | Stale | Mark/close inactive issues and PRs |

### Setup Requirements

- **pub.dev environment**: Configure `pub.dev` environment in repo Settings > Environments for OIDC publishing
- **Allow auto-merge**: Enable in Settings > General > Pull Requests > Allow auto-merge (required for Dependabot auto-merge)
- **Branch protection on main**: Require `test (stable)` status check to pass
