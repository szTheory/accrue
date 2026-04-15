---
phase: 08-install-polish-testing
reviewed: 2026-04-15T23:06:18Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - accrue/lib/accrue/auth/mock.ex
  - accrue/lib/accrue/install/patches.ex
  - accrue/test/accrue/auth/mock_test.exs
  - accrue/test/mix/tasks/accrue_install_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 08: Code Review Report

**Reviewed:** 2026-04-15T23:06:18Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed only the Phase 08 gap-closure source/test files from plans 08-08 and 08-09. The mock auth adapter is process-local, prod-guarded, and covered for the primary helper paths. The installer patch tests cover the default admin mount, webhook route, Sigra auth, test support snippet, readiness redaction, and re-run behavior for generated templates.

One installer regression remains: admin route idempotency is hard-coded to the default mount path, so custom `--admin-mount` installs can duplicate the admin mount on re-run.

## Warnings

### WR-01: Custom Admin Mounts Are Not Idempotent

**File:** `accrue/lib/accrue/install/patches.ex:196`
**Issue:** `patch_admin/3` skips only when the router already contains `accrue_admin "/billing"`. The generated snippet uses `opts.admin_mount`, so a host that installs with a custom mount such as `--admin-mount /admin/billing` will not match the hard-coded default on the next installer run. The second run appends another identical custom `accrue_admin` block, which can leave duplicate routes in the host router. The current installer tests only assert the default `"/billing"` mount and do not cover custom mount re-run idempotency.
**Fix:**
```elixir
defp patch_admin(_project, opts, %{path: path, snippet: snippet}) do
  content = File.read!(path)
  mount = opts.admin_mount || "/billing"

  cond do
    content =~ ~s(accrue_admin "#{mount}") ->
      {:skipped, path, "admin mount already configured"}

    true ->
      patched =
        content
        |> ensure_import("AccrueAdmin.Router")
        |> insert_before_final_end(snippet)

      File.write!(path, patched)
      {:changed, path, "protected accrue_admin mount"}
  end
end
```

Add a regression test in `accrue/test/mix/tasks/accrue_install_test.exs` that runs `mix accrue.install --yes --admin-mount /admin/billing` twice with `:accrue_admin` present, then asserts the router contains exactly one `accrue_admin "/admin/billing"` occurrence.

---

_Reviewed: 2026-04-15T23:06:18Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
