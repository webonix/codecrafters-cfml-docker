# codecrafters-cfml-docker

CFML (Lucee) starter for the CodeCrafters challenge [Build your own Claude Code](https://app.codecrafters.io/courses/claude-code/introduction), using [LuCLI](https://lucli.dev) in Docker (CLI only, no web server).

## What’s in this repo

- **Dockerfile** – JRE 21 Alpine + LuCLI (latest JAR) at `/opt/lucli.jar`, app at `/app`
- **.codecrafters/run.sh** – Entrypoint for CodeCrafters: runs LuCLI with `app/main.cfm`, passes args; parses `-p "prompt"` into `PROMPT` for the app
- **.codecrafters/compile.sh** – No-op (CFML is not compiled)
- **app/main.cfm** – Stage 1: reads prompt from `PROMPT` (or args), calls OpenRouter chat/completions, prints the assistant message to stdout

## Run locally

### API key (OPENROUTER_API_KEY)

- **Where to get it:** Sign up at [OpenRouter](https://openrouter.ai), then create an API key in [Keys](https://openrouter.ai/keys) (dashboard).
- **Where to save it:** Either put it in a `.env` file in this repo (recommended; `.env` is in `.gitignore` so it won’t be committed), or export it in your shell:
  ```bash
  # Option A: .env in repo root (then run: source .env  or use with docker run --env-file .env)
  echo 'OPENROUTER_API_KEY=sk-or-v1-...' > .env

  # Option B: export in your shell
  export OPENROUTER_API_KEY=your_key_here
  ```

1. **Build the image**
   ```bash
   docker build -t cfml-claude .
   ```

2. **Set your API key and run**
   ```bash
   export OPENROUTER_API_KEY=your_key_here
   docker run --rm -e OPENROUTER_API_KEY="$OPENROUTER_API_KEY" cfml-claude ./.codecrafters/run.sh -p "Say hello in one sentence"
   ```
   Or with a `.env` file: `docker run --rm --env-file .env cfml-claude ./.codecrafters/run.sh -p "Say hello in one sentence"`

   Or from inside the container (e.g. for debugging):
   ```bash
   docker run --rm -it -e OPENROUTER_API_KEY="$OPENROUTER_API_KEY" cfml-claude sh
   # then: ./.codecrafters/run.sh -p "Say hello"
   ```

`OPENROUTER_BASE_URL` defaults to `https://openrouter.ai/api/v1`; set it only if you need a different endpoint.

## Adding CFML to build-your-own-claude-code (optional)

Only relevant if you want to contribute CFML as a language to the official [build-your-own-claude-code](https://github.com/codecrafters-io/build-your-own-claude-code) repo:

1. Copy this Dockerfile (e.g. into `dockerfiles/lucli-1.0.Dockerfile` or similar) and the starter files (`.codecrafters/`, `app/main.cfm`) into the challenge’s CFML template.
2. Add a `config.yml` (or equivalent) entry for CFML that points at this Dockerfile and template, following the same pattern as the existing Python/Go options. (Check the upstream repo for the current layout.)

## Plan

See [docs/PLAN.md](docs/PLAN.md) for the full implementation plan and checklist.
