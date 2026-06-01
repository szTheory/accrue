const { test: base, expect } = require('@playwright/test');

const test = base.extend({
  context: async ({ context, request }, use) => {
    // Check out a sandbox session
    const res = await request.post('/api/sandbox');
    const token = await res.text();

    // Attach sandbox token to all requests from this context
    await context.setExtraHTTPHeaders({
      'x-sandbox-id': token
    });

    await use(context);

    // Stop the sandbox session
    await request.delete('/api/sandbox', {
      headers: {
        'x-sandbox-id': token
      }
    });
  }
});

module.exports = { test, expect };
