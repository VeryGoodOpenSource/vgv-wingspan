# Splitting Heuristics

How to turn one large diff into an ordered set of pull requests.

## Size targets

Measure against `MEANINGFUL_LINES` from `scripts/split-inventory.sh`, which excludes generated output.

| Range | Verdict |
| ----- | ------- |
| Under 500 lines | Ideal. A reviewer finishes it in one sitting. |
| 500–1,500 lines | Acceptable only when the code is repetitive or formulaic, such as a set of near-identical mappers. |
| Over 1,500 lines | Split further. |

Never propose a group over 1,500 lines without first trying to break it down. "All of the interface code" is not a valid unit if it exceeds the ceiling.

## Split on these boundaries

| Boundary | Example |
| -------- | ------- |
| Architectural layer | Data access, then business logic, then interface |
| Feature or domain | Auth changes separate from settings changes |
| Dependency direction | The shared utility first, then the code calling it |
| Sub-feature within a layer | One screen or endpoint per pull request |
| Independence | Two groups that never reference each other need not be stacked at all |

## Always split out

- **Infrastructure and configuration** — CI, build config, dependency bumps. Fast to review and often blocking other work.
- **Shared additions** — new helpers, shared components, client methods. Land the foundation before its consumers.
- **Refactors mixed with features** — refactor first, feature second. A diff that both moves code and changes behavior hides the behavior change.

## Keep a group whole when

- The files import each other directly and were changed as one unit.
- It is a model plus the single consumer that uses it, and the total is under 500 lines.
- It is a small bug fix touching a handful of files. Do not split a 30-line fix into three pull requests.

## Split a group further when

- Its meaningful diff exceeds 500 lines.
- Its files serve clearly different purposes, such as client code beside interface code beside configuration.
- A reviewer would have to context-switch to follow different parts of it.
- It contains several independent sub-features.

## Breaking down a layer that is still too large

| Layer | How to divide it |
| ----- | ---------------- |
| Business logic or domain | By related model cluster. A contract or interface goes with the cluster it serves most, or alone if large. |
| Data access | By mapper or adapter group, each with its tests. The implementation that wires them lands after. |
| Interface | By screen or component, each with its state management and tests. Scaffolding — package config, shared test helpers, the barrel or index file — goes in the first one. |
| Application wiring | Routing separately from dependency injection, or one entry point at a time. |

Splitting inside a layer produces temporary partial states: an index file exporting three of five modules, a translation file holding only some strings. That is fine. Each pull request must build and pass its own tests, but it does not have to represent the finished feature.

## Reordering to shrink the stack

A stack is only as parallel as its dependencies allow. Before settling on an order, check whether any group actually depends on the one below it. Groups with no relationship between them can start from the base branch instead, giving independent pull requests that review and merge in parallel rather than a chain that merges strictly bottom-up.
