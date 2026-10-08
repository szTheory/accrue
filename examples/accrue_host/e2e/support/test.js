const { test: base, expect } = require('@playwright/test');

const sqlSandboxEnabled = process.env.ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX !== '1';

const test = base.extend({
  sandboxId: async ({ request }, use) => {
    if (!sqlSandboxEnabled) {
      await use(null);
      return;
    }

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
      ...(sandboxId ? { userAgent: sandboxId } : {}),
      extraHTTPHeaders: {
        ...contextOptions.extraHTTPHeaders,
        ...(sandboxId ? { 'x-sandbox-id': sandboxId } : {})
      }
    });

    await use(context);

    await context.close();
  }
});

module.exports = { test, expect };
