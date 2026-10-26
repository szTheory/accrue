const fs = require("node:fs");

class TapReporter {
  onBegin(_config, suite) {
    this.total = suite.allTests().length;
    this.index = 0;
    this.lines = [];
  }

  onTestEnd(test, result) {
    this.index += 1;
    const name = test.title.replace(/[\r\n]/g, " ");
    const passed = result.status === "passed";
    this.lines.push(`${passed ? "ok" : "not ok"} ${this.index} - ${name}`);
    if (!passed && result.error?.message) {
      console.error(`${name}: ${result.error.message}`);
    }
  }

  onEnd() {
    this.lines.push(`1..${this.total}`);
    const reportPath = process.env.ACCRUE_TAP_REPORT;
    if (!reportPath) throw new Error("ACCRUE_TAP_REPORT is required");
    fs.writeFileSync(reportPath, `${this.lines.join("\n")}\n`);
  }
}

module.exports = TapReporter;
