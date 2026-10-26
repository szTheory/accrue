// Shared transient feedback. Placement and appearance belong to .ax-toast.
let toastTimeout;

export function showToast(message, { duration = 2500 } = {}) {
  if (typeof document === "undefined" || !document.body) return;
  let toast = document.querySelector("[data-ax-toast]");
  if (!toast) {
    toast = document.createElement("div");
    toast.dataset.axToast = "true";
    toast.className = "ax-toast";
    toast.setAttribute("role", "status");
    document.body.append(toast);
  }
  clearTimeout(toastTimeout);
  toast.textContent = message;
  toast.hidden = false;
  toastTimeout = setTimeout(() => { toast.hidden = true; }, duration);
}

