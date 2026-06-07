# Docker DX: stable URLs for a fleet of lib demos

**The gameplan, in one breath:** run one small shared Traefik proxy once
(`make proxy`), and every dockerized lib demo on your machine becomes reachable at
a stable `*.localhost` name on port 80 — `http://accrue.localhost`,
`http://scoria.localhost`, `http://parapet.localhost` — with **zero port conflicts,
ever**, and nothing to configure per demo. `make up` joins accrue to that proxy; if
the proxy isn't running it still boots on an auto-picked ephemeral port and the
banner prints the fallback URL. On a fresh machine, `make up` creates the shared
Docker `proxy` network before Compose starts, so skipping `make proxy` degrades to
the fallback URL instead of a cryptic external-network error. Source is bind-mounted
with warm caches, so editing a `.heex`/CSS file hot-reloads instantly and **never
re-downloads or rebuilds deps**.

If you just want to run the demo, the [README "Start Here"](../README.md#start-here)
is all you need. This doc is the *why* and the fleet-operations picture.

---

## The problem this solves

You're building several Elixir/Phoenix OSS libs at once, and each ships an admin-UI
demo on a port (Phoenix defaults to 4000). Run two and they fight over 4000. Run six
and you're maintaining a mental registry of "which lib is on which port today,"
bookmarks break every reboot, and OAuth redirect URIs (which need a *fixed* URL) are
a nightmare. Picking ports by hand is the pain.

There are a few ways out. Here's the honest comparison, because accrue's siblings
have each tried one:

| Approach | What you get | The catch |
|----------|--------------|-----------|
| **Ephemeral ports** (`127.0.0.1::4000`) | Never collides; zero setup | URL changes every boot — unbookmarkable, breaks OAuth; you re-read a banner each time |
| **Fixed port lanes** (4000/4010/4020 in `.env`) | Stable URLs | A manual registry you maintain; still collides with anything outside the registry |
| **Auto-port scanner** (hash/CLI picks a free port in a range) | Stable-ish, automatic | Raw `IP:PORT` URLs, range caps, non-standard `bin/` wrapper instead of `docker compose` |
| **Shared reverse proxy** ⭐ | Stable *named* URLs, unlimited demos, no published ports | One-time `make proxy`; `*.localhost` needs Chrome/Firefox (or a fallback for Safari) |

The shared proxy wins once you're past two demos: it's the only option that gives
**stable, human-readable URLs AND zero manual config**, and it scales to N demos by
adding one label block — no registry, no ranges.

## How it works

`make proxy` does two things, both idempotent:

1. `docker network create proxy` — a shared external Docker network (a no-op if it
   exists).
2. `docker compose -f docker/traefik/compose.yml up -d` — starts
   [Traefik](https://traefik.io) as project `dev_proxy`, owning host port 80 and
   reading the Docker socket (read-only).

Accrue's `web` service then (in `docker-compose.yml`):

- joins the `proxy` network *and* its own `default` network,
- publishes **no fixed host port** (just the ephemeral fallback), and
- carries labels that tell Traefik its route:

  ```yaml
  - traefik.enable=true
  - traefik.docker.network=proxy
  - traefik.http.routers.accrue-host.rule=Host(`accrue.localhost`)
  - traefik.http.services.accrue-host.loadbalancer.server.port=4000
  ```

Traefik watches Docker, sees those labels, and routes any request whose `Host:`
header is `accrue.localhost` to the container's port 4000. Browsers resolve
`*.localhost` to `127.0.0.1` automatically ([RFC 6761](https://www.rfc-editor.org/rfc/rfc6761)),
so `http://accrue.localhost` just works — no `/etc/hosts` editing. The Traefik
dashboard at **http://localhost:8080/dashboard/** shows every route live.

The dashboard uses Traefik's insecure API mode because this is local-only developer
infrastructure. Its ports are bound to `127.0.0.1`, and the Docker socket is mounted
read-only. Do not publish this proxy on `0.0.0.0` or reuse it as production ingress.

The proxy is the same `dev_proxy` project the sibling demos use, so bringing it up
from any one repo is shared, fleet-wide infrastructure.

## Running the whole fleet

```bash
make proxy        # once, from any repo
make up           # in accrue   -> http://accrue.localhost
# ...and in your other repos -> http://scoria.localhost, http://parapet.localhost, ...
```

Each demo is a separate Compose project, so they start/stop independently. Adding a
seventh demo is "copy the four labels, pick a name." **`make down` stops only this
demo** — it never touches the shared proxy, so you won't tear down everyone else's
routing.

**Two checkouts of *this same* lib?** Override the instance:

```bash
make up INSTANCE=accrue-foo   # -> http://accrue-foo.localhost, isolated volumes & route
```

`INSTANCE` sets the Compose project name *and* the Traefik host, so the two
checkouts get separate networks, volumes, containers, and routes — no collision.
INSTANCE must be DNS-safe lowercase: letters, numbers, and hyphens only, starting
and ending with a letter or number. Compose permits underscores, but hostnames such
as `foo_bar.localhost` are a DNS footgun, so the Makefile rejects them.

Use the Makefile as the fleet-safe interface. Direct `docker compose up` is fine for
debugging, but if you bypass `make`, set both `COMPOSE_PROJECT_NAME` and
`ACCRUE_HOST`; otherwise two checkouts with the same directory name can collide.

## The caching mental model

You should never wait on a dep download or asset rebuild for a style change. Here's
exactly what each action costs, and why:

- **Instant — editing `.heex`, CSS, or JS.** Source is bind-mounted into the
  container (`../..:/workspace`); `live_reload` plus the Tailwind/esbuild watchers
  rebuild only the changed asset and refresh the page. No restart, no `mix`, no
  network.
- **A few seconds — `make up` (warm).** The lean entrypoint runs `mix deps.get` →
  migrate → seed → boot, and **skips** `npm install` and the first-paint
  `assets.build` when the manifest hashes still match. Changing
  `assets/package.json` or `assets/package-lock.json` reruns `assets.setup`; changing
  CSS/JS/vendor/config inputs reruns the first-paint `assets.build`. Adding a hex dep
  just re-runs `deps.get` for the one new package.
- **A full build — `make build` or `make reset`.** Only when `Dockerfile.dev` /
  OS-level deps change, or you want a clean slate. `make reset` wipes the named
  Compose volumes, rebuilds detached, prints the same banner as `make up`, and then
  follows logs. Even then, it **re-links** Hex and npm packages from the host-bind caches
  (`~/.cache/accrue-docker/{hex,npm}`) instead of re-downloading them — those caches
  survive `docker compose down --volumes`.

Why no `COPY`-source layering or BuildKit cache mounts (scoria's
[one-Dockerfile-trick](https://fly.io/phoenix-files/speed-up-your-boot-times-with-this-one-dockerfile-trick/)
shape)? Because accrue's dev image never copies source or runs `mix` at *build*
time — it bind-mounts source and resolves deps at *run* time into named + host-bind
volumes. The image layer cache only invalidates when `bin/` changes. The runtime
caches already give us the fast loop, so there's nothing to gain from build-layer
gymnastics here.

## Footguns (lessons learned)

- **The image builds a HarfBuzz NIF from Rust source — don't "fix" it by emulating.**
  `harfbuzz_ex` (pulled by `rendro`, the default invoice-PDF renderer) does the text
  shaping for PDF invoices, and it ships precompiled NIFs for `x86_64-linux` but
  **not `aarch64-linux`**. The tempting shortcut — pin the container to `linux/amd64`
  so it uses the x86 NIF — is a **trap on Apple Silicon**: amd64 emulation
  (Rosetta/QEMU) corrupts the BEAM compiler (you'll see `prim_tty` NIF crashes,
  `module ... already compiled`, or `ets:lookup_element` `badarg`). Instead we run
  **native-arch** and build the NIF from source: `Dockerfile.dev` adds a Rust
  toolchain and sets `RUSTLER_PRECOMPILATION_EXAMPLE_BUILD=1`. `harfbuzz_ex` uses
  `rustybuzz` (pure Rust), so this needs **no system HarfBuzz/C++ libs** — just
  `cargo`. The NIF compiles once and is cached in the `mix_deps`/`mix_build` volumes.
  If `DOCKER_DEFAULT_PLATFORM=linux/amd64` is set on Apple Silicon, the Makefile
  fails before Compose starts; unset it for this repo.
- **Host build artifacts must not leak into the container.** `accrue_host`
  `path:`-depends on the sibling packages (`accrue`, `accrue_admin`, `accrue_portal`),
  so the `../..:/workspace` bind mount drags in *their* `deps/` and `_build/` too —
  compiled by *your machine's* native Elixir/OTP, which is often a newer version than
  the image. Loading those inside the container corrupts the build with
  `** (ArgumentError) ... module Accrue.MixProject is already compiled`. The compose
  file shadows each sibling's `deps`/`_build` with named volumes so the container
  compiles everything fresh and Linux-native. If you add a new `path:` dependency,
  add a matching pair of volume shadows.
- **Don't mount a volume over `/root/.mix`.** That directory holds the baked
  Hex/rebar archives; shadowing it with an empty volume makes `mix` "could not find
  Hex" on a detached boot. We persist `/root/.hex` (download cache) and `/root/.npm`
  only — never `/root/.mix`.
- **Safari / `curl` don't resolve `*.localhost`.** Chrome and Firefox do. For Safari
  or scripts, use the `http://127.0.0.1:<port>` fallback the banner prints, or add a
  dnsmasq wildcard (`address=/localhost/127.0.0.1`).
- **Port 80 or 8080 can be owned by another local proxy.** `make proxy` is shared
  fleet infrastructure and binds `127.0.0.1:80` plus
  `127.0.0.1:8080`. If it fails, check `docker ps` and stop the other local proxy or
  standardize that repo on the same `dev_proxy` stack.
- **The proxy is shared — don't `down` it from one lib.** `make down` is scoped to
  this demo's project. To actually stop the proxy (rare):
  `docker compose -p dev_proxy -f docker/traefik/compose.yml down`.
- **Renaming services leaves orphans.** `make up` runs with `--remove-orphans` so a
  renamed/removed container is cleaned up instead of lingering on the network.
- **`db` is intentionally unpublished.** Postgres is reached by service name on the
  internal network, so port 5432 never collides across demos. Need a DB GUI? Copy
  `docker-compose.override.yml.example` to `docker-compose.override.yml`; Docker
  picks a free loopback port by default, and `docker compose port db 5432` prints it.
  Set `PGPORT=55432` only when a tool needs a stable port for this instance.
- **A changed path dependency needs new volume shadows.** If `mix.exs` gains another
  sibling `path:` dependency under `/workspace`, add matching `deps` and `_build`
  named-volume shadows in `docker-compose.yml`; otherwise host build artifacts can
  leak into the Linux container.

## References

- Docker's Traefik guide — https://docs.docker.com/guides/traefik/
- Compose `name:` / project precedence — https://docs.docker.com/compose/how-tos/project-name/
- `*.localhost` is reserved loopback — https://www.rfc-editor.org/rfc/rfc6761
- The shared proxy this mirrors lives in the sibling `scoria` repo
  (`docker/traefik/compose.yml`); accrue ships its own identical copy so the demo
  stands alone.
