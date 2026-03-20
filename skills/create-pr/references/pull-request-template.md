# Pull Request Template Reference

Default template to use when `.github/PULL_REQUEST_TEMPLATE.md` does not exist in the working directory.

## Template

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
- **Description:** synthesise the commit bodies into one clear paragraph. Mention the ticket number.
- **Evidence:** omit the section entirely if there are no UI changes; include a `<details>` placeholder if there are.
- **Type of Change:** mark the applicable box(es) with `x` based on commit types:
  - `feat` → New feature
  - `fix` → Bug fix
  - `refactor` → Code refactor
  - `chore` / `ci` / `build` / `docs` → Chore or matching type
  - breaking change → Breaking change
