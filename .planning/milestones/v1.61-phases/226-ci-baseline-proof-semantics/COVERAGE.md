# API Coverage — GitHub Actions REST

> Full coverage by default. Phase 226 integrates the read-only Actions evidence surface; mutating workflow controls and raw forensic downloads are explicit opt-outs.

| capability | decision | reason |
|---|---|---|
| list `ci.yml` workflow runs and run metadata | INTEGRATE | |
| get one workflow run by immutable run ID | INTEGRATE | |
| list paginated jobs and steps for every run attempt | INTEGRATE | |
| get one job's timing, conclusion, runner, matrix-name, and step metadata | INTEGRATE | |
| list run artifacts as immutable evidence metadata and links | INTEGRATE | |
| read workflow/config files at each immutable head SHA | INTEGRATE | |
| download raw job logs | OPT-OUT | Raw logs remain Actions-owned forensic evidence and are excluded from the privacy-safe checked-in baseline per D-01 and D-06. |
| download artifact contents | OPT-OUT | Artifact contents may contain reports, traces, screenshots, payloads, or user data and remain outside the durable evidence pack per D-01 and D-06. |
| dispatch workflows | OPT-OUT | Phase 226 observes existing runs and does not create provider or full-CI executions through the API. |
| rerun jobs or workflows | OPT-OUT | Rerun attempts are measured as reliability evidence; initiating reruns would change the evidence being observed. |
| cancel or delete workflow runs | OPT-OUT | Phase 226 is read-only and must preserve CI evidence. |
| approve deployments or mutate pending deployments | OPT-OUT | Deployment control is unrelated to CI baseline, provider proof, or setup ownership. |
| manage workflow, secrets, variables, permissions, or branch protection | OPT-OUT | These mutation surfaces are outside Phase 226 and would violate its evidence-before-optimization boundary. |
