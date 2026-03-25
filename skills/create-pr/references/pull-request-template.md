# Pull Request Template Reference

Default template to use when no project-level PR template is found.

## Discover template

Check for a project-level template in this order:

1. **GitHub:** `.github/PULL_REQUEST_TEMPLATE.md`
2. **GitLab:** `.gitlab/merge_request_templates/Default.md`
3. **Fallback:** use the default template below.

```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null \
  || cat .gitlab/merge_request_templates/Default.md 2>/dev/null
```

If a project-level template is found, use it as the structure. Strip HTML comments and pre-fill where possible.

## Default template

Use this when no project-level template exists:

```markdown
## Description

<!-- One paragraph describing what this PR does and why. Be concise and clear. -->

## Evidence

<!-- Omit if no UI changes. Otherwise add:
<details>
<summary>Element description</summary>

[image/video]

</details>
-->

## Type of Change

- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 🛠️ Bug fix (non-breaking change which fixes an issue)
- [ ] ❌ Breaking change (fix or feature that would cause existing functionality to change)
- [ ] 🧹 Code refactor
- [ ] ✅ Build configuration change
- [ ] 📝 Documentation
- [ ] 🗑️ Chore
```

## Filling the template

- **Do not include HTML comments in the output.**
- **Description:** synthesize the commit bodies into one clear paragraph. Mention the ticket number.
- **Evidence:** omit the section entirely if there are no UI changes; include a `<details>` placeholder if there are.
- **Type of Change:** mark the applicable box(es) with `x` based on commit types:
  - `feat` → New feature
  - `fix` → Bug fix
  - `refactor` → Code refactor
  - `chore` / `ci` / `build` / `docs` → Chore or matching type
  - breaking change → Breaking change
