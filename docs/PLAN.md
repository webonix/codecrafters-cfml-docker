---
name: LuCLI Docker Claude Code
overview: "CFML starter for CodeCrafters Build your own Claude Code using LuCLI in Docker: JRE + LuCLI JAR, run.sh, compile.sh, app/main.cfm."
todos: []
isProject: false
---

# LuCLI + Docker: CFML Starter for Build your own Claude Code

## Goal

Deliver a **CFML language option** for the CodeCrafters challenge [Build your own Claude Code](https://app.codecrafters.io/courses/claude-code/introduction):

- User selects CFML; they get a repo with a **Dockerfile** (JRE + [LuCLI](https://lucli.dev) JAR) and **starter code** (`.codecrafters/run.sh`, `.codecrafters/compile.sh`, `app/main.cfm`).
- The test runner runs `/app/.codecrafters/run.sh` with arguments (e.g. `-p "prompt"`). The script invokes LuCLI to run `app/main.cfm`, which calls the OpenRouter LLM API and (as the user progresses) implements tools and the agent loop.

---

## 1. Dockerfile

- **Base**: Slim JRE image (e.g. `eclipse-temurin:21-jre-alpine`).
- **LuCLI**: Download the LuCLI JAR from [LuCLI releases](https://github.com/cybersonic/LuCLI/releases) into the image (e.g. `/opt/lucli.jar`). Use the **latest** release URL for simplicity.
- **WORKDIR**: `/app`. The platform copies the user's code into `/app`; the runner executes `/app/.codecrafters/run.sh`.
- **Env**: Optional `ENV LUCLI_JAR=/opt/lucli.jar` for `run.sh`.
- **No ENTRYPOINT/CMD**: The test runner calls `run.sh` directly.
- **Copy**: For a self-contained repo (local testing), `COPY . /app`. For use inside build-your-own-claude-code, the Dockerfile may only install the JAR; the platform supplies the code.

---

## 2. .codecrafters/run.sh

- **Role**: Required by CodeCrafters; the test runner executes this script with challenge arguments.
- **Behaviour**: Run the CFML program (LuCLI executing `app/main.cfm`) and pass through all arguments.
- **Sketch**:
  - Shebang `#!/bin/sh`, `set -e`.
  - Resolve `LUCLI_JAR` (default `/opt/lucli.jar`), `cd` to repo root (parent of `.codecrafters`).
  - `exec java -jar "$LUCLI_JAR" app/main.cfm "$@"`. LuCLI runs the script path as the first argument and passes remaining args to CFML (see [LuCLI README](https://github.com/cybersonic/LuCLI): `java -jar lucli.jar myscript.cfs arg1 arg2`).
- **Permissions**: Executable (`chmod +x`).

---

## 3. .codecrafters/compile.sh

- **Role**: CodeCrafters runs this before `run.sh` when the file exists. Required for compliance.
- **Behaviour**: No-op (CFML is not compiled).
- **Content**: `#!/bin/sh` and `exit 0`.
- **Permissions**: Executable (`chmod +x`).

---

## 4. app/main.cfm

Single CFML entrypoint (no Application.cfc or index.cfm).

**Stage 1 – Communicate with the LLM**

- Read the prompt: from args (if LuCLI passes them) or from an env var (e.g. `PROMPT`) set by `run.sh` if needed.
- Read `OPENROUTER_API_KEY` (required; exit non-zero if missing) and `OPENROUTER_BASE_URL` (default `https://openrouter.ai/api/v1`).
- POST to `#baseUrl#/chat/completions` with `cfhttp`: `Authorization: Bearer #apiKey#`, body `{"model":"anthropic/claude-haiku-4.5","messages":[{"role":"user","content":"#prompt#"}]}`.
- Parse the JSON response and print the assistant message to stdout (`writeOutput(...)`).
- On error (missing key, HTTP failure): stderr message and non-zero exit (e.g. Java `System.exit(1)`).

**Later stages (as user progresses)**

- Add a `tools` array to the request (Read, then Write, then Bash); parse `tool_calls` from the response; execute the requested tool and re-call the API with the result in `messages`; repeat until the model returns a final answer (agent loop).

---

## 5. Repo layout

```
codecrafters-cfml-docker/
├── .gitignore
├── Dockerfile
├── README.md
├── app/
│   └── main.cfm
├── docs/
│   └── PLAN.md
└── .codecrafters/
    ├── run.sh
    └── compile.sh
```

Optional when contributing to build-your-own-claude-code: `config.yml` (and Dockerfile in `dockerfiles/`, e.g. `cfml-1.0.Dockerfile` or `lucli-1.0.Dockerfile`), following the same pattern as Python/Go.

---

## 6. Implementation checklist

| Item                     | Action                                                                                                           |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| .gitignore               | Add; ignore .env, OS/editor files (e.g. .DS_Store, *.swp)                                                        |
| Dockerfile               | JRE base; download LuCLI JAR (latest) to /opt/lucli.jar; WORKDIR /app; optional COPY . /app                       |
| .codecrafters/run.sh     | Shebang, set -e; cd to app root; exec java -jar "$LUCLI_JAR" app/main.cfm "$@" (no "run" subcommand); chmod +x   |
| .codecrafters/compile.sh | #!/bin/sh, exit 0; chmod +x                                                                                      |
| app/main.cfm             | Stage 1: prompt + OPENROUTER_* env, cfhttp to OpenRouter, writeOutput assistant message; exit non-zero on error  |
| README.md                | What this is (LuCLI + Docker for Claude Code); how to run locally; how to add CFML to build-your-own-claude-code |

---

## 7. Confirmation of checklist (point 6)

| #   | Item                         | Confirmed / correction                                                                                                                                                                                                                                                                                                                        |
| --- | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **.gitignore**               | ✓ Add .gitignore; ignore .env, .DS_Store, editor swap/backup files.                                                                                                                                                                                                                                                                           |
| 2   | **Dockerfile**               | ✓ JRE 17+ (e.g. eclipse-temurin:21-jre-alpine). Download LuCLI JAR from `https://github.com/cybersonic/LuCLI/releases` (use **latest** release URL). Install to `/opt/lucli.jar`. WORKDIR `/app`. Optional `COPY . /app` for self-contained local runs. No ENTRYPOINT/CMD.                                                                      |
| 3   | **.codecrafters/run.sh**     | ✓ Required. Shebang `#!/bin/sh`, `set -e`. Resolve `LUCLI_JAR` (default `/opt/lucli.jar`), `cd` to repo root. **Correct invocations:** `exec java -jar "$LUCLI_JAR" app/main.cfm "$@"` — LuCLI takes script path then args ([LuCLI README](https://github.com/cybersonic/LuCLI)); there is no `run` subcommand. Make executable (`chmod +x`). |
| 4   | **.codecrafters/compile.sh** | ✓ Required for CodeCrafters compliance. Content: `#!/bin/sh` and `exit 0`. Make executable (`chmod +x`).                                                                                                                                                                                                                                      |
| 5   | **app/main.cfm**             | ✓ Stage 1: read prompt (from argv if LuCLI passes it, or from env set by run.sh), read `OPENROUTER_API_KEY` and `OPENROUTER_BASE_URL`, `cfhttp` POST to OpenRouter chat/completions, parse JSON, `writeOutput` assistant message. On error: stderr and non-zero exit (e.g. `createObject("java","java.lang.System").exit(1)`).                |
| 6   | **README.md**                | ✓ Describe: LuCLI + Docker for Build your own Claude Code; how to build/run locally; how to add CFML to build-your-own-claude-code (copy Dockerfile + starter into that repo).                                                                                                                                                                |

---

## 8. Notes

- **LuCLI CLI**: Use `java -jar lucli.jar app/main.cfm "$@"` (script path then args). LuCLI requires Java 17+. How CFML receives args may be URL scope or a LuCLI-specific mechanism; check LuCLI docs if `-p "prompt"` is not available in CFML and fall back to run.sh parsing and env (e.g. `PROMPT`).
- **Exit code**: Failures must produce a non-zero process exit for the tester to fail the stage.
- **JAR URL**: Use LuCLI **latest** release URL in the Dockerfile.
