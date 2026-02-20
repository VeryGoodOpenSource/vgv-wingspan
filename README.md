# Wingspan

AI-assisted workflows for Flutter and Dart that follow Very Good Ventures best practices and standards.

![wingspan logo by very good ventures in blue](./assets/wingspan-logo.png)

## Installation

### Local development

```bash
git clone git@github.com:VeryGoodOpenSource/wingspan.git
```

**Single session** — loads the plugin for the current session only:

```bash
cd /to/your/project
claude --plugin-dir <wingspan-path>/plugins/wingspan
```

**Persistent** — installs the plugin so it loads automatically on every session:

```bash
cd /to/your/project
claude
# then inside Claude Code:
/plugin marketplace add <wingspan-path>
/plugin install wingspan@wingspan-marketplace
```

### Vision

![wingspan vision](./assets/vision.png)
