// examples/accrue_host/assets/js/braintree_vault_acquisition.js

import dropin from "braintree-web-drop-in";

const BraintreeVaultAcquisition = {
  mounted() {
    this.setupBraintree();
  },
  updated() {
    // Re-setup if necessary when DOM updates
    if (!this.instance) {
      this.setupBraintree();
    }
  },
  destroyed() {
    if (this.instance) {
      this.instance.teardown();
      this.instance = null;
    }
  },
  setupBraintree() {
    const container = this.el.querySelector('#braintree-dropin-container');
    const submitButton = this.el.querySelector('#braintree-submit-button');
    const clientToken = this.el.dataset.clientToken;

    if (!container || !submitButton || !clientToken) {
      return;
    }

    dropin.create({
      authorization: clientToken,
      container: container
    }, (createErr, instance) => {
      if (createErr) {
        console.error('Braintree create error:', createErr);
        return;
      }
      this.instance = instance;

      submitButton.addEventListener('click', (event) => {
        event.preventDefault();
        submitButton.disabled = true;

        instance.requestPaymentMethod((requestErr, payload) => {
          if (requestErr) {
            console.error('Braintree request payment method error:', requestErr);
            submitButton.disabled = false;
            return;
          }

          // payload.nonce is the vaulted token.
          this.pushEvent("vault_acquisition_success", {
            payment_method_token: payload.nonce,
            plan_id: this.el.dataset.planId,
            operation_id: this.el.dataset.operationId
          });
        });
      });
    });
  }
};

export default BraintreeVaultAcquisition;
