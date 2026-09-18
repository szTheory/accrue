# API Coverage — GitHub read-only repository observation

> Full coverage by default. Opt-outs are explicit, reasoned decisions. This matrix is limited to the GitHub API surface authorized by Phase 229 decisions D-02, D-08, and D-10.

| capability | decision | reason |
|---|---|---|
| Read the repository default/main ref and its full object SHA | INTEGRATE | |
| Read every open pull-request head and its full object SHA | INTEGRATE | |
| Read every `release/*` branch and its full object SHA | INTEGRATE | |
| Read a bounded recent GitHub Actions run set with full head SHAs | INTEGRATE | |
| Mutate repository settings or contents | OPT-OUT | Phase 229 is an observation-only recovery-safety phase per D-08. |
| Publish packages, releases, or artifacts | OPT-OUT | Publication is outside v1.62 and requires separate authorization. |
| Dispatch, rerun, or cancel workflows | OPT-OUT | CI execution belongs to Phase 231; Phase 229 permits bounded reads only. |
| Create, edit, close, merge, or retarget pull requests | OPT-OUT | PR changes and integration belong to later phases per D-10. |
| Create, update, delete, or force-move refs or tags through GitHub | OPT-OUT | Published history and the v1.61 tag are immutable; Phase 229 performs no remote writes. |
| Resolve or waive ship windows | OPT-OUT | Phase 229 inventories ship-window truth; resolution belongs to Phase 231. |
