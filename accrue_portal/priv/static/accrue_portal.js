(function () {
  function initHostedFields() {
    if (!window.braintree) return;

    document.querySelectorAll("[data-portal-hosted-fields]").forEach(function (form) {
      if (form.dataset.hostedFieldsBound === "1") return;

      var token = form.dataset.clientToken;
      var nonceInput = form.querySelector("[data-braintree-nonce-input]");
      var errorNode = form.querySelector("[data-braintree-error]");

      if (!token || !nonceInput) return;

      form.dataset.hostedFieldsBound = "1";

      window.braintree.client.create({ authorization: token }, function (clientErr, clientInstance) {
        if (clientErr) {
          if (errorNode) errorNode.textContent = "Unable to start card entry.";
          return;
        }

        window.braintree.hostedFields.create(
          {
            client: clientInstance,
            styles: {
              input: {
                color: "#111418",
                "font-size": "16px",
                "font-family": "Iowan Old Style, Palatino Linotype, Georgia, serif"
              }
            },
            fields: {
              number: { selector: fieldSelector(form, "number"), placeholder: "4111 1111 1111 1111" },
              expirationDate: { selector: fieldSelector(form, "expirationDate"), placeholder: "MM / YY" },
              cvv: { selector: fieldSelector(form, "cvv"), placeholder: "123" }
            }
          },
          function (hostedFieldsErr, hostedFields) {
            if (hostedFieldsErr) {
              if (errorNode) errorNode.textContent = "Unable to load secure card fields.";
              return;
            }

            form.addEventListener("submit", function (event) {
              if (form.dataset.hostedFieldsSubmitting === "1") return;

              event.preventDefault();
              form.dataset.hostedFieldsSubmitting = "1";
              if (errorNode) errorNode.textContent = "";

              hostedFields.tokenize(function (tokenizeErr, payload) {
                form.dataset.hostedFieldsSubmitting = "0";

                if (tokenizeErr) {
                  if (errorNode) errorNode.textContent = tokenizeErr.message || "Unable to tokenize card.";
                  return;
                }

                nonceInput.value = payload.nonce;
                form.submit();
              });
            });
          }
        );
      });
    });
  }

  function fieldSelector(form, fieldName) {
    var field = form.querySelector('[data-braintree-field="' + fieldName + '"]');
    if (!field.id) {
      field.id = "accrue-portal-" + fieldName + "-" + Math.random().toString(36).slice(2);
    }
    return "#" + field.id;
  }

  document.addEventListener("DOMContentLoaded", initHostedFields);
  window.addEventListener("phx:page-loading-stop", initHostedFields);
})();
