(function () {
  var Hooks = {};

  Hooks.BraintreeHostedFields = {
    mounted: function () {
      if (!window.braintree) return;
      if (this.el.dataset.hostedFieldsBound === "1") return;

      var token = this.el.dataset.clientToken;
      var errorNode = this.el.querySelector("[data-braintree-error]");
      var submitButton = this.el.querySelector("[data-checkout-submit]");

      if (!token) return;

      this.el.dataset.hostedFieldsBound = "1";
      this.hostedFields = null;
      this.readyToSubmit = false;
      this.tokenizing = false;
      this.submissionSent = false;

      window.braintree.client.create({ authorization: token }, function (clientErr, clientInstance) {
        if (clientErr) {
          setInlineError(errorNode, "Unable to start card entry.");
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
              setInlineError(errorNode, "Unable to load secure card fields.");
              return;
            }

            this.hostedFields = hostedFieldsInstance;

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
      var nonceInput = this.el.querySelector("[data-braintree-nonce-input]");
      if (nonceInput) nonceInput.value = "";

      this.hostedFields.tokenize(
        function (tokenizeErr, payload) {
          if (tokenizeErr) {
            this.tokenizing = false;
            setSubmitting(submitButton, false);

            if (nonceInput) nonceInput.value = "";

            if (this.el.dataset.portalHostedFields === "payment-method") {
              setInlineError(errorNode, tokenizeErr.message || "Unable to tokenize card.");
              return;
            }

            this.pushEvent("checkout_failed", {
              message: tokenizeErr.message || "Unable to tokenize card."
            });

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

          if (!payload || !payload.nonce || !contextPin) {
            this.tokenizing = false;
            setSubmitting(submitButton, false);
            setInlineError(errorNode, "Checkout context expired. No payment was submitted.");
            return;
          }

          this.pushEvent("checkout_tokenized", {
            nonce: payload.nonce,
            context_pin: contextPin
          }, function () {
            this.tokenizing = false;
            setSubmitting(submitButton, false);
          }.bind(this));
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
    if (node) node.textContent = message || "";
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
