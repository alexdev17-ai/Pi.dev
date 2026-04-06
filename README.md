# pi.dev

Pi coding agent setup for Windows 11 / WSL2 with OpenRouter and the `playwright-safe` skill.

## Prerequisites

- Windows 11, WSL2 (Ubuntu 22.04), Docker Desktop running
- nvm installed in WSL2 with Node >= 20 active
- OpenRouter account: https://openrouter.ai/keys

## Install

Open WSL2 and run:

```bash
cd /mnt/c/Users/HAAK/pi.dev
bash install/install-pi.sh
```

Follow the prompts. Your OpenRouter API key will be requested — paste it only when the terminal asks.

## Launch Pi

```bash
pi
```

## playwright-safe skill

Pi's only browser automation path. Called via:
```bash
playwright_safe_cli --operation goto --url "https://example.com"
```

Operations: `goto`, `click`, `extract_text`, `extract_links`, `screenshot`, `form_login`

All browser calls run inside an ephemeral Docker container and pass through an injection guard before Pi sees the output.
