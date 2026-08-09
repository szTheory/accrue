# Dialyzer warnings to ignore.
#
# Mailglass mailable pattern: `Mailglass.Renderer.render_html/2` accepts
# `is_function(fun, 1)` for deferred HEEx component rendering, but
# `Swoosh.Email.html_body/2` (imported via `use Mailglass.Mailable`) types
# its second arg as `binary() | nil`. The function-component path works at
# runtime (verified by the email parity test suite), but Dialyzer flags
# every `html_body(fn _ -> html(assigns) end)` call as a contract break.
# Suppress until upstream Mailglass adds an `html_body/2` helper that
# accepts function-or-binary.

[
  {"lib/accrue/emails/card_expiring_soon.ex"},
  {"lib/accrue/emails/coupon_applied.ex"},
  {"lib/accrue/emails/invoice_finalized.ex"},
  {"lib/accrue/emails/invoice_paid.ex"},
  {"lib/accrue/emails/invoice_payment_failed.ex"},
  {"lib/accrue/emails/payment_failed.ex"},
  {"lib/accrue/emails/payment_succeeded.ex"},
  {"lib/accrue/emails/receipt.ex"},
  {"lib/accrue/emails/refund_issued.ex"},
  {"lib/accrue/emails/subscription_canceled.ex"},
  {"lib/accrue/emails/subscription_paused.ex"},
  {"lib/accrue/emails/subscription_resumed.ex"},
  {"lib/accrue/emails/trial_ended.ex"},
  {"lib/accrue/emails/trial_ending.ex"},

  # `lib/accrue/workers/mailer.ex:284`: the same Swoosh.Email.html_body
  # function-component contract gap as the mailables (the worker wraps the
  # delivered email's html_body to append an invoice URL note).
  # `lib/accrue/workers/mailer.ex:316`: `idempotency_key(:payment_succeeded, _)`
  # head is reachable only via the compatibility alias path; Dialyzer infers
  # the active dispatch types as `:receipt | :payment_failed` from the worker
  # call site, but the third clause is intentionally retained for the alias.
  {"lib/accrue/workers/mailer.ex"},

  # The v1.59 entitlements implementation is already shipped and passes its
  # runtime contract suites, but Dialyzer 1.19/OTP 28 cannot fully resolve
  # several nested embedded-schema and generated-contract types. Keep this
  # baseline explicit by warning kind so new warnings in these files remain
  # visible to CI rather than suppressing whole directories.
  {"lib/accrue/config.ex", :invalid_contract},
  {"lib/accrue/entitlements/apple/admission.ex", :pattern_match_cov},
  {"lib/accrue/entitlements/apple/reconciliation.ex", :pattern_match_cov},
  {"lib/accrue/entitlements/apple/reconciliation.ex", :pattern_match},
  {"lib/accrue/entitlements/compatibility.ex", :no_return},
  {"lib/accrue/entitlements/compatibility.ex", :call},
  {"lib/accrue/entitlements/decision_cases.ex", :unknown_type},
  {"lib/accrue/entitlements/decision_cases/markdown.ex", :call_without_opaque},
  {"lib/accrue/entitlements/offline.ex", :unknown_type},
  {"lib/accrue/entitlements/offline/issuer.ex", :unknown_type},
  {"lib/accrue/entitlements/offline/issuer.ex", :call_without_opaque},
  {"lib/accrue/entitlements/offline/reconnect.ex", :unknown_type},
  {"lib/accrue/entitlements/offline/registration.ex", :unknown_type},
  {"lib/accrue/entitlements/offline/source_coordinator.ex", :unknown_type},
  {"lib/accrue/entitlements/reconcile.ex", :pattern_match},
  {"test/support/entitlements/decision_case_contract_consumer.ex", :unknown_type},
  {"test/support/entitlements/offline_golden_vector_verifier.ex", :pattern_match},
  {"test/support/entitlements/offline_golden_vector_verifier.ex", :guard_fail},
  {"test/support/entitlements/offline_golden_vector_verifier.ex", :unused_fun}
]
