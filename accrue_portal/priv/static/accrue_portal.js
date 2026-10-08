(function () {
  var Hooks = {};
  var hostedFieldsHooks = [];

  function destroyHostedFieldsHook(hook) {
    if (!hook || hook.isDestroyed) return;

    hook.isDestroyed = true;
    hook.lifecycleGeneration = (hook.lifecycleGeneration || 0) + 1;
    if (hook.sdkLoadTimer) window.clearTimeout(hook.sdkLoadTimer);
    if (hook.themeMedia && hook.themeMediaListener) hook.themeMedia.removeEventListener("change", hook.themeMediaListener);

    var nonceInput = hook.el && hook.el.querySelector("[data-braintree-nonce-input]");
    if (nonceInput) nonceInput.value = "";
    hook.readyToSubmit = false;
    hook.tokenizing = false;
    hook.submissionSent = false;

    if (hook.hostedFields && hook.hostedFields.teardown) {
      hook.hostedFields.teardown(function () {});
    }
    hook.hostedFields = null;

    var index = hostedFieldsHooks.indexOf(hook);
    if (index !== -1) hostedFieldsHooks.splice(index, 1);
  }

  function teardownAsyncResource(resource, callback) {
    if (!resource || typeof resource.teardown !== "function") {
      callback(null);
      return;
    }

    var callbackCalled = false;
    function finish(error) {
      if (callbackCalled) return;
      callbackCalled = true;
      callback(error || null);
    }

    try {
      resource.teardown(finish);
    } catch (error) {
      finish(error);
    }
  }

  function finishStaleHostedFieldsSetup(hook, createGeneration, clientInstance, hostedFieldsInstance) {
    var teardownError = null;
    teardownAsyncResource(hostedFieldsInstance, function (hostedFieldsError) {
      if (hostedFieldsError) teardownError = hostedFieldsError;
      teardownAsyncResource(clientInstance, function (clientError) {
        if (clientError && !teardownError) teardownError = clientError;
        if (hook.hostedFieldsSetupGeneration === createGeneration) {
          hook.hostedFieldsSetupInFlight = false;
          hook.hostedFieldsSetupGeneration = null;
        }

        if (hook.isDestroyed || !hook.hostedFieldsRetryAfterPending) return;

        if (teardownError) {
          hook.hostedFieldsRetryAfterPending = false;
          hook.hostedFieldsSetupFailed = true;
          setSubmitDisabled(hook.el.querySelector("[data-checkout-submit]"), true);
          setInlineError(
            hook.el.querySelector("[data-braintree-error]"),
            "Secure card fields could not be safely reset. Refresh this page to try again."
          );
          return;
        }

        hook.hostedFieldsRetryAfterPending = false;
        hook.el.dataset.hostedFieldsBound = "0";
        hook.mounted();
      });
    });
  }

  Hooks.BraintreeHostedFields = {
    mounted: function () {
      if (this.isDestroyed) return;
      this.isDestroyed = false;
      if (hostedFieldsHooks.indexOf(this) === -1) hostedFieldsHooks.push(this);
      if (!this.themeMedia) {
        this.themeMedia = window.matchMedia("(prefers-color-scheme: dark)");
        this.themeMediaListener = function () { refreshHostedFields(this); }.bind(this);
        this.themeMedia.addEventListener("change", this.themeMediaListener);
      }
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
      if (this.sdkLoadTimer) {
        window.clearTimeout(this.sdkLoadTimer);
        this.sdkLoadTimer = null;
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
      this.hostedFieldsSetupInFlight = true;
      this.hostedFieldsRetryAfterPending = false;
      this.lifecycleGeneration = (this.lifecycleGeneration || 0) + 1;
      var createGeneration = this.lifecycleGeneration;
      this.hostedFieldsSetupGeneration = createGeneration;

      window.braintree.client.create({ authorization: token }, function (clientErr, clientInstance) {
        if (this.isDestroyed || createGeneration !== this.lifecycleGeneration) {
          finishStaleHostedFieldsSetup(this, createGeneration, clientInstance, null);
          return;
        }
        if (clientErr) {
          this.hostedFieldsSetupInFlight = false;
          this.hostedFieldsSetupGeneration = null;
          setSubmitDisabled(submitButton, true);
          setInlineError(errorNode, "Secure card entry could not start. Refresh this page to try again.");
          return;
        }

        var styles = hostedFieldStyles(this.el);
        this.hostedFieldStylesSnapshot = JSON.stringify(styles);
        window.braintree.hostedFields.create(
          {
            client: clientInstance,
            styles: styles,
            fields: {
              number: { selector: fieldSelector(this.el, "number"), placeholder: "4111 1111 1111 1111" },
              expirationDate: { selector: fieldSelector(this.el, "expirationDate"), placeholder: "MM / YY" },
              cvv: { selector: fieldSelector(this.el, "cvv"), placeholder: "123" }
            }
          },
          function (hostedFieldsErr, hostedFieldsInstance) {
            if (this.isDestroyed || createGeneration !== this.lifecycleGeneration) {
              finishStaleHostedFieldsSetup(this, createGeneration, clientInstance, hostedFieldsInstance);
              return;
            }
            if (hostedFieldsErr) {
              this.hostedFieldsSetupInFlight = false;
              this.hostedFieldsSetupGeneration = null;
              setSubmitDisabled(submitButton, true);
              setInlineError(errorNode, "Secure card fields could not load. Refresh this page to try again.");
              return;
            }

            this.hostedFields = hostedFieldsInstance;
            this.hostedFieldsSetupInFlight = false;
            this.hostedFieldsSetupGeneration = null;
            this.hostedFieldsRetryAfterPending = false;
            setSubmitting(submitButton, false);
            setInlineError(errorNode, "Secure card fields are ready.");

            if (this.el.dataset.hostedFieldsSubmitBound !== "1") this.el.addEventListener(
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
            this.el.dataset.hostedFieldsSubmitBound = "1";
          }.bind(this)
        );
      }.bind(this));
    },

    updated: function () {
      var nonceInput = this.el.querySelector("[data-braintree-nonce-input]");
      if (nonceInput) nonceInput.value = "";
      this.lifecycleGeneration = (this.lifecycleGeneration || 0) + 1;
      this.readyToSubmit = false;
      this.tokenizing = false;
      if (this.hostedFieldsSetupFailed) {
        setSubmitDisabled(this.el.querySelector("[data-checkout-submit]"), true);
        return;
      }
      if (this.hostedFields) {
        setSubmitting(this.el.querySelector("[data-checkout-submit]"), false);
        refreshHostedFields(this);
      } else if (this.hostedFieldsSetupInFlight) {
        this.hostedFieldsRetryAfterPending = true;
        setSubmitDisabled(this.el.querySelector("[data-checkout-submit]"), true);
      } else if (window.braintree) {
        this.el.dataset.hostedFieldsBound = "0";
        this.mounted();
      }
    },

    destroyed: function () {
      destroyHostedFieldsHook(this);
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
      var lifecycleGeneration = this.lifecycleGeneration;

      this.hostedFields.tokenize(
        function (tokenizeErr, payload) {
          if (this.isDestroyed || lifecycleGeneration !== this.lifecycleGeneration) {
            this.tokenizing = false;
            if (nonceInput) nonceInput.value = "";
            return;
          }

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

  window.addEventListener("pagehide", function () {
    hostedFieldsHooks.slice().forEach(destroyHostedFieldsHook);
  });

  document.addEventListener("submit", function (event) {
    var form = event.target;
    if (!form || form.nodeName !== "FORM" || !form.hasAttribute("data-confirm")) return;

    if (form.dataset.confirmAccepted === "1") {
      delete form.dataset.confirmAccepted;
      return;
    }

    event.preventDefault();
    if (!window.confirm(form.getAttribute("data-confirm"))) return;

    form.dataset.confirmAccepted = "1";
    if (typeof form.requestSubmit === "function") {
      if (event.submitter) form.requestSubmit(event.submitter);
      else form.requestSubmit();
    } else {
      form.submit();
    }
  });

  function hostedFieldStyles(form) {
    var fields = {};
    var backgrounds = [];
    var primaryCandidate = getComputedStyle(document.documentElement).getPropertyValue("--accrue-ink");
    var mutedCandidate = getComputedStyle(document.documentElement).getPropertyValue("--accrue-slate");

    ["number", "expirationDate", "cvv"].forEach(function (name) {
      var field = form.querySelector('[data-braintree-field="' + name + '"]');
      var background = field ? normalizedColor(getComputedStyle(field).backgroundColor, "#FFFFFF") : "#FFFFFF";
      backgrounds.push(background);
      fields[name] = {
        input: { color: readableHostedFieldColor(primaryCandidate, [background]) }
      };
    });

    var averageLuminance = backgrounds.reduce(function (sum, background) {
      return sum + colorLuminance(background);
    }, 0) / backgrounds.length;
    var invalidCandidate = averageLuminance > 0.45 ? "#9B1C1C" : "#FFB4AB";
    var invalid = readableHostedFieldColor(invalidCandidate, backgrounds);
    var muted = readableHostedFieldColor(mutedCandidate, backgrounds);

    return {
      input: {
        color: fields.number.input.color,
        "font-size": "16px",
        "font-family": "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "font-weight": "400",
        "line-height": "1.5"
      },
      ".number": { color: fields.number.input.color },
      ".expirationDate": { color: fields.expirationDate.input.color },
      ".cvv": { color: fields.cvv.input.color },
      ".invalid": { color: invalid },
      "::placeholder": { color: muted },
    };
  }

  function readableHostedFieldColor(candidate, backgrounds) {
    var normalized = normalizedColor(candidate, "");
    if (normalized && isReadableAgainstAllBackgrounds(normalized, backgrounds)) return normalized;

    var dark = normalizedColor("#111418", "#111418");
    var light = normalizedColor("#FFFFFF", "#FFFFFF");
    var darkMinimum = minimumContrastRatio(dark, backgrounds);
    var lightMinimum = minimumContrastRatio(light, backgrounds);
    return darkMinimum >= lightMinimum ? dark : light;
  }

  function isReadableAgainstAllBackgrounds(foreground, backgrounds) {
    return backgrounds.length > 0 && backgrounds.every(function (background) {
      return colorContrastRatio(foreground, background) >= 4.5;
    });
  }

  function minimumContrastRatio(foreground, backgrounds) {
    return backgrounds.reduce(function (minimum, background) {
      return Math.min(minimum, colorContrastRatio(foreground, background));
    }, Infinity);
  }

  function normalizedColor(value, fallback) {
    var probe = document.createElement("span");
    probe.style.color = "";
    probe.style.color = String(value || "").trim();
    if (!probe.style.color) return fallback;
    document.body.appendChild(probe);
    var normalized = getComputedStyle(probe).color;
    probe.remove();
    if (!/^rgba?\(/i.test(normalized) && !/^color\(srgb\s/i.test(normalized)) return fallback;
    return normalized;
  }

  function colorLuminance(color) {
    var rgb = colorChannels(color);
    if (!rgb) return 1;
    var linear = rgb.map(function (channel) {
      var value = channel;
      return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
  }

  function colorChannels(color) {
    var normalized = String(color || "").trim();
    var values = normalized.match(/(?:\d*\.)?\d+/g);
    if (!values || values.length < 3) return null;

    var isSrgb = /^color\(srgb\s/i.test(normalized);
    var alpha = values.length > 3 ? Number(values[3]) : 1;
    if (alpha < 1) return null;

    return values.slice(0, 3).map(function (channel) {
      var value = Number(channel);
      return isSrgb ? value : value / 255;
    });
  }

  function colorContrastRatio(foreground, background) {
    if (!colorChannels(foreground) || !colorChannels(background)) return 0;
    var foregroundLuminance = colorLuminance(foreground);
    var backgroundLuminance = colorLuminance(background);
    var lighter = Math.max(foregroundLuminance, backgroundLuminance);
    var darker = Math.min(foregroundLuminance, backgroundLuminance);
    return (lighter + 0.05) / (darker + 0.05);
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
    hostedFieldsHooks.slice().forEach(refreshHostedFields);
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

  function refreshHostedFields(hook) {
    if (!hook || hook.isDestroyed || !hook.hostedFields) return;
    var nextStyles = JSON.stringify(hostedFieldStyles(hook.el));
    if (nextStyles === hook.hostedFieldStylesSnapshot) return;
    hook.lifecycleGeneration = (hook.lifecycleGeneration || 0) + 1;
    hook.readyToSubmit = false;
    hook.tokenizing = false;
    var nonce = hook.el.querySelector("[data-braintree-nonce-input]");
    if (nonce) nonce.value = "";
    setSubmitDisabled(hook.el.querySelector("[data-checkout-submit]"), true);
    var old = hook.hostedFields;
    hook.hostedFields = null;
    teardownAsyncResource(old, function (teardownError) {
      if (hook.isDestroyed) return;
      if (teardownError) {
        hook.hostedFieldsSetupFailed = true;
        setSubmitDisabled(hook.el.querySelector("[data-checkout-submit]"), true);
        setInlineError(
          hook.el.querySelector("[data-braintree-error]"),
          "Secure card fields could not be safely reset. Refresh this page to try again."
        );
        return;
      }

      hook.el.dataset.hostedFieldsBound = "0";
      hook.mounted();
    });
  }

  function handleThemeClick(event) {
    var target = event.target.closest
      ? event.target.closest("[data-portal-theme]")
      : null;

    if (!target) return;

    applyTheme(target.getAttribute("data-portal-theme"));
  }

  document.addEventListener("click", handleThemeClick);

  window.addEventListener("phx:portal:restore-focus", function (event) {
    var id = event.detail && event.detail.id;
    if (!id) return;

    window.requestAnimationFrame(function () {
      var target = document.getElementById(id);
      if (target && typeof target.focus === "function") {
        target.focus({ preventScroll: true });
      }
    });
  });

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
