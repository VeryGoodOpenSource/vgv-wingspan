# VGV Wingspan

[![Very Good Ventures][logo_white]][very_good_ventures_link_dark]
[![Very Good Ventures][logo_black]][very_good_ventures_link_light]

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
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
