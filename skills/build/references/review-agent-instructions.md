# Review Agent Instructions

Write your full detailed report to `docs/reviews/<name>.md` (create the directory if needed).
Then return ONLY a short structured summary to the parent context in this format:

```markdown
## <Agent Name> Summary
**Report**: `docs/reviews/<name>.md` (<word_count> words)
**Critical**: <count> | **Important**: <count> | **Suggestions**: <count>
### Findings
- [Critical] <one-line description>
- [Important] <one-line description>
- [Suggestion] <one-line description>
```

Do NOT return the full report text. Only return the summary above.
