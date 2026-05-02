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
      if (this.hostedFields && this.hostedFields.teardown) {
        this.hostedFields.teardown(function () {});
      }
    },

    tokenizeAndSubmit: function (errorNode, submitButton) {
      if (!this.hostedFields) return;

      setInlineError(errorNode, "");
      setSubmitting(submitButton, true);

      this.hostedFields.tokenize(
        function (tokenizeErr, payload) {
          if (tokenizeErr) {
            setSubmitting(submitButton, false);

            this.pushEvent("checkout_failed", {
              message: tokenizeErr.message || "Unable to tokenize card."
            });

            return;
          }

          this.pushEvent("checkout_tokenized", { nonce: payload.nonce }, function () {
            setSubmitting(submitButton, false);
          });
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

  function bootLiveSocket() {
    if (!window.Phoenix || !window.Phoenix.LiveView || window.accruePortalLiveSocket) return;

    var csrf = document.querySelector("meta[name='csrf-token']");
    var liveSocket = new window.Phoenix.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
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
