export const PreserveDisclosure = {
  mounted() {
    this.disclosureDesiredOpen = this.el.open;
    this.captureDisclosureIntent = (event) => {
      const summary = event.target.closest?.("summary");
      if (summary?.parentElement === this.el) {
        this.disclosureDesiredOpen = !this.el.open;
      }
    };
    this.el.addEventListener("click", this.captureDisclosureIntent, true);
    if (this.el.hasAttribute("data-disclosure-dismiss")) {
      this.dismissDisclosure = (event) => {
        if (!this.el.open) return;
        const escape = event.type === "keydown" && event.key === "Escape";
        const outside = event.type === "pointerdown" && !this.el.contains(event.target);
        if (!escape && !outside) return;
        this.disclosureDesiredOpen = false;
        this.el.open = false;
        if (escape) {
          event.preventDefault();
          event.stopPropagation();
          this.el.querySelector("summary")?.focus();
        }
      };
      this.el.addEventListener("keydown", this.dismissDisclosure);
      this.el.ownerDocument.addEventListener("pointerdown", this.dismissDisclosure);
    }
  },

  beforeUpdate() {
    if (typeof this.disclosureDesiredOpen !== "boolean") {
      this.disclosureDesiredOpen = this.el.open;
    }
  },

  updated() {
    this.el.open = this.disclosureDesiredOpen;
  },

  destroyed() {
    this.el.removeEventListener("click", this.captureDisclosureIntent, true);
    if (this.dismissDisclosure) {
      this.el.removeEventListener("keydown", this.dismissDisclosure);
      this.el.ownerDocument.removeEventListener("pointerdown", this.dismissDisclosure);
    }
  }
};
