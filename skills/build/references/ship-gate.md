# Ship Gate

The plan's `success-criteria` block is the ship gate. Parse it and resolve the gate set and
the authoritative command before running the drive-to-green loop.

| Case | Gate set and authoritative command |
| ---- | ---------------------------------- |
| Block present with a `VERIFICATION COMMAND` | Gate set is the non-manual `verify:` commands; the `VERIFICATION COMMAND` is authoritative |
| Block present, `VERIFICATION COMMAND` missing, non-manual `verify:` lines exist | Synthesize the authoritative command by joining those `verify:` commands with `&&` |
| Only `verify: manual` criteria | Skip the loop; go straight to the manual-criteria checklist |
| No `success-criteria` block (plan predates it) | Fall back to the detected project suite — formatter, linter, test runner — and warn the user the plan has no machine-checkable criteria |

Never treat an empty runnable set or an absent block as green.

Then follow the [drive to green procedure](drive-to-green.md) with that gate set and
authoritative command. Do not proceed to cleanup until the authoritative gate is green and
any manual criteria are confirmed.
