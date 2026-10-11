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
  }
};
