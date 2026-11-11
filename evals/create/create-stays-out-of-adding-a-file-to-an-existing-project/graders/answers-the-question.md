---
type: llm
---

Judge only the text of the response, not whether the suggested filename is the one you would pick.

PASS if the response names a path and filename for the new module inside the project that already exists, for example a new file in the same source directory as the file it was shown.

FAIL if it instead starts a new project, asks what kind of project to create, or lists plugins to install.
