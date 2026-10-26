#!/usr/bin/env python3
"""Local replay of a .github/workflows/ci.yml job's `run:` steps (Phase 249 planning tool).

Extracts each run: block to NN-<slug>.sh under --out and, with --run, executes each
file as `bash -eo pipefail FILE` (never `bash -c` on a dumped string).
Never point this at host-docker-smoke (routed to Phase 250).
"""
import argparse
import os
import re
import subprocess
import sys
import time

import yaml


def repo_root():
    return subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:60] or "step"


def sub_exprs(text, exprs):
    if not isinstance(text, str):
        return text
    for k, v in exprs.items():
        text = re.sub(r"\$\{\{\s*" + re.escape(k) + r"\s*\}\}", lambda _m, v=v: v, text)
    return text


EXPR_RE = re.compile(r"\$\{\{.*?\}\}", re.S)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--job", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--run", action="store_true")
    ap.add_argument("--only", action="append", default=[])
    ap.add_argument("--skip", action="append", default=[])
    ap.add_argument("--workflow", default=".github/workflows/ci.yml")
    ap.add_argument("--env", action="append", default=[])
    ap.add_argument("--expr", action="append", default=[])
    a = ap.parse_args()

    root = repo_root()
    wf_path = a.workflow if os.path.isabs(a.workflow) else os.path.join(root, a.workflow)
    with open(wf_path) as fh:
        wf = yaml.safe_load(fh)
    jobs = wf.get("jobs", {})
    if a.job not in jobs:
        print(f"unknown job {a.job!r}; available: {', '.join(sorted(jobs))}", file=sys.stderr)
        return 2
    job = jobs[a.job]
    exprs = {}
    for e in a.expr:
        k, _, v = e.partition("=")
        exprs[k.strip()] = v
    overrides = {}
    for e in a.env:
        k, _, v = e.partition("=")
        overrides[k] = v

    os.makedirs(a.out, exist_ok=True)
    outs = {n: os.path.join(a.out, n) for n in ("github_output", "github_step_summary", "github_env")}
    for p in outs.values():
        open(p, "a").close()

    job_default_wd = (job.get("defaults") or {}).get("run", {}).get("working-directory")
    wf_default_wd = (wf.get("defaults") or {}).get("run", {}).get("working-directory")
    job_coe = job.get("continue-on-error") is True
    only = [re.compile(x, re.I) for x in a.only]
    skip = [re.compile(x, re.I) for x in a.skip]

    results = []
    unresolved_all = []
    for idx, step in enumerate(job.get("steps", []), 1):
        if "run" not in step:
            continue
        name = step.get("name") or f"step-{idx}"
        nn = f"{idx:02d}"
        env = {}
        unresolved = []
        for layer in (wf.get("env") or {}, job.get("env") or {}, step.get("env") or {}):
            for k, v in layer.items():
                v = sub_exprs(str(v), exprs)
                if EXPR_RE.search(v):
                    if k not in overrides:
                        unresolved.append(k)
                    continue
                env[k] = v
        env.update(overrides)
        body = sub_exprs(step["run"], exprs)
        if EXPR_RE.search(body):
            unresolved.append("<run body>: " + ", ".join(sorted(set(EXPR_RE.findall(body)))))
        wd = step.get("working-directory") or job_default_wd or wf_default_wd
        wd_abs = os.path.join(root, wd) if wd else root
        lines = ["#!/usr/bin/env bash", f"cd {sh_quote(wd_abs)}"]
        for k, v in env.items():
            lines.append(f"export {k}={sh_quote(v)}")
        lines.append(body if body.endswith("\n") else body + "\n")
        fn = os.path.join(a.out, f"{nn}-{slug(name)}.sh")
        with open(fn, "w") as fh:
            fh.write("\n".join(lines))
        if unresolved:
            unresolved_all.append((nn, name, unresolved))

        cond = step.get("if")
        cond = sub_exprs(str(cond), exprs) if cond is not None else None
        reason = None
        if only and not any(r.search(name) for r in only):
            reason = "not matched by --only"
        elif any(r.search(name) for r in skip):
            reason = "matched --skip"
        advisory = job_coe or step.get("continue-on-error") is True
        cond_note = f" [if: {cond}]" if cond and cond.strip() not in ("true", "success()", "always()") else ""
        if not a.run:
            results.append(("EXTRACT", nn, name + cond_note, 0.0, False))
            continue
        if reason:
            results.append(("SKIP", nn, f"{name} ({reason})", 0.0, advisory))
            continue
        penv = dict(os.environ)
        penv.update(
            GITHUB_OUTPUT=outs["github_output"],
            GITHUB_STEP_SUMMARY=outs["github_step_summary"],
            GITHUB_ENV=outs["github_env"],
        )
        t0 = time.time()
        with open(fn[:-3] + ".log", "w") as log:
            rc = subprocess.run(["bash", "-eo", "pipefail", fn], cwd=root, env=penv,
                                stdout=log, stderr=subprocess.STDOUT).returncode
        dt = time.time() - t0
        if advisory:
            status = "ADVISORY-PASS" if rc == 0 else "ADVISORY-FAIL"
        else:
            status = "PASS" if rc == 0 else "FAIL"
        results.append((status, nn, name + cond_note, dt, advisory))

    for status, nn, name, dt, _ in results:
        if status == "SKIP" and a.only:
            continue
        print(f"{status} {nn} {name} ({dt:.1f}s)")
    for nn, name, un in unresolved_all:
        print(f"UNRESOLVED {nn} {name}: {un}")
    if a.run:
        counts = {}
        for r in results:
            counts[r[0]] = counts.get(r[0], 0) + 1
        print("TOTALS " + " ".join(f"{k}={v}" for k, v in sorted(counts.items())) + f" out={a.out}")
        return 1 if counts.get("FAIL") else 0
    print(f"TOTALS extracted={len(results)} out={a.out}")
    return 0


def sh_quote(s):
    return "'" + str(s).replace("'", "'\\''") + "'"


if __name__ == "__main__":
    sys.exit(main())
