const { test: base, expect } = require('@playwright/test');

const test = base.extend({
  sandboxId: async ({ request }, use) => {
    // Check out a sandbox session
    const res = await request.post('/api/sandbox');
    const token = await res.text();

    await use(token);

    // Stop the sandbox session
    await request.delete('/api/sandbox', {
      headers: {
        'x-sandbox-id': token
      }
    });
  },

  context: async ({ browser, contextOptions, sandboxId }, use) => {
    const context = await browser.newContext({
      ...contextOptions,
      userAgent: sandboxId,
      extraHTTPHeaders: {
        ...contextOptions.extraHTTPHeaders,
        'x-sandbox-id': sandboxId
      }
    });

    await use(context);

    await context.close();
  }
});

module.exports = { test, expect };
