# Phase 164: Docker DX & Optimized Caching - Research

**Researched:** 2024-10-24
**Domain:** Developer Experience / Docker Infrastructure
**Confidence:** HIGH

## Summary

The `examples/accrue_host` application is a Phoenix 1.7+ project that serves as a demo app. It utilizes path dependencies (`../../accrue`, `../../accrue_admin`, `../../accrue_portal`) to link against the local monorepo packages. To build a seamless Docker local dev environment (EVD-03) that is fast and optimizes caching (EVD-04), we must address the "Path Dependency Trap" and the "Host NIF Conflict" problem. 

The optimal architecture places the `docker-compose.yml` in `examples/accrue_host/` but mounts the entire repository parent directory (`../..:/workspace`). To optimize caching and prevent MacOS/Linux binary conflicts with Elixir compiled artifacts, we must use Docker named volumes for `deps`, `_build`, and `assets/node_modules`.

**Primary recommendation:** Use a lightweight `Dockerfile.dev` based on `elixir:1.17-slim` and a `docker-compose.yml` with strategically placed named volumes to isolate `_build` and `deps`, ensuring immediate container boots and fast local iterations.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| EVD-03: Docker local dev environment | Developer Tooling / Infrastructure | Container Engine | Docker Compose orchestrates Postgres and the Elixir container. |
| EVD-04: Docker caching layers | Developer Tooling / Build System | File System (Volumes) | Docker named volumes cache Hex packages and `_build` artifacts across container restarts. |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVD-03 | Create a seamless Docker-based local development environment for the demo app (`examples/accrue_host`). | `docker-compose.yml` linking a `db` service and `web` service with the correct context. |
| EVD-04 | Optimize Docker caching layers (e.g., Tailwind, Hex deps) to ensure rapid local iteration without redownloading dependencies. | Use Docker named volumes for `deps` and `_build` to isolate and persist compiler artifacts and Hex downloads. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `elixir:1.17-slim` | 1.17 | Base image | Official Debian-based image; avoids Alpine `musl` compilation issues with NIFs. |
| PostgreSQL | 15+ | Database | Matches production; `accrue_host` defaults to `postgres` user/pass. |
| Docker Compose | v2 | Orchestration | Standard tool for multi-container local dev environments. |

**Version verification:** 
```bash
# verified via `docker run --rm elixir:1.17-slim elixir -v`
```

## Architecture Patterns

### Recommended Project Structure
```
examples/accrue_host/
├── Dockerfile.dev         # Dev-specific Dockerfile installing inotify-tools & node
├── docker-compose.yml     # Orchestrates 'db' and 'web', mounts ../.. as /workspace
├── entrypoint.sh          # Runs `mix setup` and `mix phx.server`
```

### Pattern 1: Path Dependency Bind Mounts + Artifact Isolation
**What:** Mounting the entire monorepo to allow local editing, while masking compilation folders with named volumes.
**When to use:** Local development of Elixir apps with local path dependencies across Mac/Linux hosts.
**Example:**
```yaml
# docker-compose.yml
services:
  web:
    build:
      context: ../..
      dockerfile: examples/accrue_host/Dockerfile.dev
    volumes:
      - ../..:/workspace
      # Isolate dependencies and build artifacts to prevent host OS conflict
      - mix_deps:/workspace/examples/accrue_host/deps
      - mix_build:/workspace/examples/accrue_host/_build
      - assets_node_modules:/workspace/examples/accrue_host/assets/node_modules
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Running `mix deps.get` inside a dev Dockerfile with the expectation of caching. 
  *Why it's bad:* In local dev, the host bind mount (`.:/workspace`) immediately overwrites the pre-built `deps` directory from the image layer. 
  *What to do instead:* Use a lightweight image and rely on Docker named volumes (`mix_deps`, `mix_build`). The first boot downloads deps into the volume; subsequent boots use the cached volume instantly.
- **Anti-pattern:** Using `elixir:alpine`.
  *Why it's bad:* Alpine uses `musl` libc, which often fails to compile Erlang NIFs (like `bcrypt_elixir`) without complex workarounds. Use `debian-slim`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-OS NIF conflicts | Custom path overrides in `mix.exs` | Docker named volumes for `_build` | Docker natively handles volume masking over bind mounts. |
| Live-reload on Linux | Custom file watchers | `inotify-tools` | Required package for Phoenix live-reload in Debian/Linux containers. |

## Common Pitfalls

### Pitfall 1: Hardcoded Localhost in Database Config
**What goes wrong:** The Phoenix app in the Docker container tries to connect to `localhost` and fails to find the Postgres container.
**Why it happens:** `examples/accrue_host/config/dev.exs` hardcodes `hostname: "localhost"`.
**How to avoid:** Update `config/dev.exs` to use an environment variable with a fallback: `hostname: System.get_env("PGHOST") || "localhost"`. Set `PGHOST=db` in `docker-compose.yml`.

### Pitfall 2: Node.js Missing from Container
**What goes wrong:** `mix setup` fails at the `cmd --cd assets npm install` step.
**Why it happens:** Elixir base images do not include Node.js.
**How to avoid:** Install `nodejs` and `npm` in the `Dockerfile.dev` via `apt-get`.

## Code Examples

### Dockerfile.dev
```dockerfile
FROM elixir:1.17-slim

RUN apt-get update -y && \
    apt-get install -y build-essential inotify-tools git postgresql-client nodejs npm && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /workspace/examples/accrue_host

EXPOSE 4000

CMD ["bash", "-c", "mix setup && mix phx.server"]
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker | Containerization | ✓ | 29.5.2 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit & Playwright |
| Config file | `mix.exs` |
| Quick run command | `docker compose exec web mix test` |
| Full suite command | `docker compose exec web mix verify.full` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVD-03 | Container boot & DB connect | smoke | `docker compose up -d && curl -f http://localhost:4000` | ❌ Wave 0 |
| EVD-04 | Caching mechanism | manual | Verify `deps` persist on restart | ❌ Wave 0 |

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements.

## Sources

### Primary (HIGH confidence)
- Verified `examples/accrue_host/config/dev.exs` database credentials (`postgres`/`postgres`).
- Verified `examples/accrue_host/mix.exs` aliases (`assets.setup` uses `npm`).
- Verified `accrue_dep` path requirements necessitating `../..` build context.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Elixir docker DX is a well-solved pattern.
- Architecture: HIGH - Docker compose with volume isolation is the exact solution for this setup.
- Pitfalls: HIGH - Found the hardcoded `localhost` in `dev.exs`.

**Research date:** 2024-10-24
**Valid until:** Stable
