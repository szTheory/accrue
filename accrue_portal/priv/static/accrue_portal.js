(function () {
  var Hooks = {};

  Hooks.BraintreeHostedFields = {
    mounted: function () {
      var errorNode = this.el.querySelector("[data-braintree-error]");
      var submitButton = this.el.querySelector("[data-checkout-submit]");

      if (!window.braintree) {
        setSubmitDisabled(submitButton, true);
        this.sdkLoadAttempts = (this.sdkLoadAttempts || 0) + 1;
        if (this.sdkLoadAttempts > 100) {
          setInlineError(errorNode, "Secure card entry could not load. Refresh this page to try again.");
          return;
        }
        setInlineError(errorNode, "Loading secure card fields...");
        this.sdkLoadTimer = window.setTimeout(function () {
          if (!this.isDestroyed) this.mounted();
        }.bind(this), 50);
        return;
      }
      if (this.el.dataset.hostedFieldsBound === "1") return;

      var token = this.el.dataset.clientToken;

      if (!token) {
        setSubmitDisabled(submitButton, true);
        setInlineError(errorNode, "Secure card entry is unavailable. Return to your account and try again.");
        return;
      }

      this.el.dataset.hostedFieldsBound = "1";
      this.hostedFields = null;
      this.readyToSubmit = false;
      this.tokenizing = false;
      this.submissionSent = false;

      window.braintree.client.create({ authorization: token }, function (clientErr, clientInstance) {
        if (clientErr) {
          setSubmitDisabled(submitButton, true);
          setInlineError(errorNode, "Secure card entry could not start. Refresh this page to try again.");
          return;
        }

        window.braintree.hostedFields.create(
          {
            client: clientInstance,
            styles: hostedFieldStyles(),
            fields: {
              number: { selector: fieldSelector(this.el, "number"), placeholder: "4111 1111 1111 1111" },
              expirationDate: { selector: fieldSelector(this.el, "expirationDate"), placeholder: "MM / YY" },
              cvv: { selector: fieldSelector(this.el, "cvv"), placeholder: "123" }
            }
          },
          function (hostedFieldsErr, hostedFieldsInstance) {
            if (hostedFieldsErr) {
              setSubmitDisabled(submitButton, true);
              setInlineError(errorNode, "Secure card fields could not load. Refresh this page to try again.");
              return;
            }

            this.hostedFields = hostedFieldsInstance;
            setSubmitting(submitButton, false);
            setInlineError(errorNode, "Secure card fields are ready.");

            this.el.addEventListener(
              "submit",
              function (event) {
                if (this.el.dataset.portalHostedFields === "payment-method") {
                  if (this.submissionSent) {
                    event.preventDefault();
                    return;
                  }

                  if (this.readyToSubmit) {
                    this.readyToSubmit = false;
                    this.submissionSent = true;
                    return;
                  }

                  event.preventDefault();
                  if (this.tokenizing) return;
                  this.tokenizeAndSubmit(errorNode, submitButton);
                  return;
                }

                if (this.tokenizing || this.submissionSent) {
                  event.preventDefault();
                  return;
                }

                if (this.readyToSubmit) {
                  this.readyToSubmit = false;
                  return;
                }

                event.preventDefault();
                this.tokenizeAndSubmit(errorNode, submitButton);
              }.bind(this)
            );
          }.bind(this)
        );
      }.bind(this));
    },

    destroyed: function () {
      this.isDestroyed = true;
      if (this.sdkLoadTimer) window.clearTimeout(this.sdkLoadTimer);
      var nonceInput = this.el.querySelector("[data-braintree-nonce-input]");
      if (nonceInput) nonceInput.value = "";
      this.readyToSubmit = false;
      this.tokenizing = false;
      this.submissionSent = false;

      if (this.hostedFields && this.hostedFields.teardown) {
        this.hostedFields.teardown(function () {});
      }
      this.hostedFields = null;
    },

    tokenizeAndSubmit: function (errorNode, submitButton) {
      if (!this.hostedFields) return;
      if (this.el.dataset.portalHostedFields === "payment-method" && this.tokenizing) return;

      setInlineError(errorNode, "");
      this.tokenizing = true;
      setSubmitting(submitButton, true);
      setInlineError(errorNode, "Securing your card details...");
      var nonceInput = this.el.querySelector("[data-braintree-nonce-input]");
      if (nonceInput) nonceInput.value = "";

      this.hostedFields.tokenize(
        function (tokenizeErr, payload) {
          if (tokenizeErr) {
            this.tokenizing = false;
            setSubmitting(submitButton, false);

            if (nonceInput) nonceInput.value = "";

            if (this.el.dataset.portalHostedFields === "payment-method") {
              setInlineError(errorNode, invalidCardError(tokenizeErr)
                ? "Check the card number, expiration, and security code, then try again."
                : "Secure card tokenization failed. No payment was submitted. Try again.");
              return;
            }

            setInlineError(errorNode, invalidCardError(tokenizeErr)
              ? "Check the card number, expiration, and security code, then try again."
              : "Secure card tokenization failed. No payment was submitted. Try again.");

            return;
          }

          if (this.el.dataset.portalHostedFields === "payment-method") {
            if (!nonceInput || !payload || !payload.nonce) {
              this.tokenizing = false;
              setSubmitting(submitButton, false);
              setInlineError(errorNode, "Unable to tokenize card.");
              return;
            }

            nonceInput.value = payload.nonce;
            this.tokenizing = false;
            this.readyToSubmit = true;

            if (this.el.requestSubmit) {
              this.el.requestSubmit();
            } else {
              this.readyToSubmit = false;
              this.submissionSent = true;
              this.el.submit();
            }

            return;
          }

          var contextPinInput = this.el.querySelector('[name="context_pin"]');
          var contextPin = contextPinInput ? contextPinInput.value : "";

          if (!nonceInput || !payload || !payload.nonce || !contextPin) {
            this.tokenizing = false;
            setSubmitting(submitButton, false);
            setInlineError(errorNode, "Checkout context expired. No payment was submitted.");
            return;
          }

          setInlineError(errorNode, "Submitting your payment securely. Keep this page open.");

          if (!this.el.action || this.el.method !== "post") {
            this.pushEvent("checkout_tokenized", {
              nonce: payload.nonce,
              context_pin: contextPin
            }, function () {
              this.tokenizing = false;
              setSubmitting(submitButton, false);
            }.bind(this));
            return;
          }

          nonceInput.value = payload.nonce;
          this.tokenizing = false;
          this.submissionSent = true;
          submitCheckout(this.el, nonceInput, errorNode);
        }.bind(this)
      );
    }
  };

  function hostedFieldStyles() {
    return {
      input: {
        color: "#111418",
        "font-size": "16px",
        "font-family": "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "font-weight": "400",
        "line-height": "1.5"
      },
      "input.invalid": {
        color: "#B42318"
      },
      "::placeholder": {
        color: "#5D6A73"
      }
    };
  }

  function fieldSelector(form, fieldName) {
    var field = form.querySelector('[data-braintree-field="' + fieldName + '"]');

    if (!field.id) {
      field.id = "accrue-portal-" + fieldName + "-" + Math.random().toString(36).slice(2);
    }

    return "#" + field.id;
  }

  function setInlineError(node, message) {
    if (!node) return;
    node.setAttribute("role", "status");
    node.setAttribute("aria-live", "polite");
    node.textContent = message || "";
  }

  function invalidCardError(error) {
    return error.code === "HOSTED_FIELDS_FIELDS_INVALID" ||
      (error.details && Array.isArray(error.details.invalidFieldKeys) && error.details.invalidFieldKeys.length > 0);
  }

  function submitCheckout(form, nonceInput, errorNode) {
    var body = new URLSearchParams(new FormData(form));

    window.fetch(form.action, {
      method: "POST",
      credentials: "same-origin",
      headers: { Accept: "text/html" },
      body: body
    }).then(function (response) {
      window.location.assign(response.url || form.action);
    }).catch(function () {
      nonceInput.value = "";
      setInlineError(
        errorNode,
        "We couldn't confirm whether your payment went through. Check your billing status or contact support before trying again."
      );
    });
  }

  function setSubmitting(button, submitting) {
    if (!button) return;

    if (!button.dataset.labelDefault) {
      button.dataset.labelDefault = button.textContent;
    }

    button.disabled = !!submitting;
    button.textContent = submitting
      ? button.dataset.labelProcessing || button.dataset.labelDefault
      : button.dataset.labelDefault;
  }

  function setSubmitDisabled(button, disabled) {
    if (button) button.disabled = !!disabled;
  }

  // --- Theme picker ------------------------------------------------------
  // Delegated (document-level) so it survives LiveView DOM patches without
  // re-binding. SSR already sets <html data-theme> from the accrue_theme
  // cookie, so this only handles user clicks — no FOUC, no inline script.
  function applyTheme(choice) {
    if (choice !== "system" && choice !== "light" && choice !== "dark") return;

    document.documentElement.dataset.theme = choice;
    document.cookie =
      "accrue_theme=" + choice + "; path=/; max-age=31536000; samesite=lax";

    var buttons = document.querySelectorAll("[data-portal-theme]");

    for (var i = 0; i < buttons.length; i++) {
      var button = buttons[i];
      var active = button.getAttribute("data-portal-theme") === choice;

      button.setAttribute("aria-pressed", active ? "true" : "false");

      if (active) {
        button.classList.add("is-active");
      } else {
        button.classList.remove("is-active");
      }
    }
  }

  function handleThemeClick(event) {
    var target = event.target.closest
      ? event.target.closest("[data-portal-theme]")
      : null;

    if (!target) return;

    applyTheme(target.getAttribute("data-portal-theme"));
  }

  document.addEventListener("click", handleThemeClick);

  function bootLiveSocket() {
    var liveView = window.LiveView || (window.Phoenix && window.Phoenix.LiveView);

    if (!window.Phoenix || !liveView || window.accruePortalLiveSocket) return;

    var csrf = document.querySelector("meta[name='csrf-token']");
    var liveSocket = new liveView.LiveSocket("/live", window.Phoenix.Socket, {
      hooks: Hooks,
      params: {
        _csrf_token: csrf ? csrf.getAttribute("content") : null
      }
    });

    liveSocket.connect();
    window.accruePortalLiveSocket = liveSocket;
  }

  window.addEventListener("phx:page-loading-stop", bootLiveSocket);

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bootLiveSocket);
  } else {
    bootLiveSocket();
  }
})();
