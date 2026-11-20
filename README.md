![VGV Wingspan, AI-assisted engineering workflows: a blue pixel texture beside the name, with the VGV logo in the corner](assets/readme-header.png)

# VGV Wingspan

🦋 AI-assisted workflows that follow [Very Good Ventures][vgv_link] best practices and standards.

The plugin lives in [`plugin/`](plugin/). Its [README](plugin/README.md) covers installation, skills, agents and hooks.

## Repository layout

| Path                                 | What it holds                                                     |
| ------------------------------------ | ----------------------------------------------------------------- |
| [`plugin/`](plugin/)                 | Everything the plugin loads. This is the folder users install.    |
| [`evals/`](evals/)                   | The `claude plugin eval` suite. Not part of the installed plugin. |
| [`tool/`](tool/)                     | Repository tooling, such as the shared-file sync script.          |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to add or change a skill, and how to test it locally.         |

[vgv_link]: https://verygood.ventures
