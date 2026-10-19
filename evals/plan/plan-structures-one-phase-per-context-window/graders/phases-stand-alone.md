---
type: llm
weight: 2
---

PASS if every phase is sized to be implemented and merged on its own and leaves the project working — for example a first phase that adds the export job and its tests behind nothing user facing, and a later phase that adds the screen that triggers it.

FAIL if the phases cannot stand alone, for example a phase that leaves the project not building until a later one lands, or a split of "write the code" then "write the tests".
