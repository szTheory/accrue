#!/usr/bin/env node

import assert from "node:assert/strict";
import { createPrivateKey, sign } from "node:crypto";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const productionEndpoint = "https://api.storekit.apple.com";
const sandboxEndpoint = "https://api.storekit-sandbox.apple.com";
const pollIntervalMs = 15_000;
const pollAttempts = 8;

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is required`);
  return value;
}

export function base64url(value) {
  return Buffer.from(value).toString("base64url");
}

function safeError(response, body) {
  const errorCode = typeof body?.errorCode === "number" ? ` errorCode=${body.errorCode}` : "";
  return `Apple API request failed: http=${response.status}${errorCode}`;
}

function authorizationToken() {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "ES256", kid: required("APPLE_SERVER_API_KEY_ID"), typ: "JWT" }));
  const payload = base64url(
    JSON.stringify({
      iss: required("APPLE_SERVER_API_ISSUER_ID"),
      iat: now,
      exp: now + 55 * 60,
      aud: "appstoreconnect-v1",
      bid: required("APPLE_SERVER_API_BUNDLE_ID")
    })
  );
  const unsigned = `${header}.${payload}`;
  const key = createPrivateKey(required("APPLE_SERVER_API_PRIVATE_KEY").replace(/\\n/g, "\n"));
  const signature = sign("sha256", Buffer.from(unsigned), { key, dsaEncoding: "ieee-p1363" });
  return `${unsigned}.${signature.toString("base64url")}`;
}

async function appleRequest(url, jwt) {
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${jwt}`, Accept: "application/json" },
    method: url.endsWith("/test") ? "POST" : "GET"
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(safeError(response, body));
  return body;
}

export function endpoint() {
  const environment = (process.env.APPLE_SERVER_API_ENVIRONMENT || "production").toLowerCase();
  if (environment === "production") return productionEndpoint;
  if (environment === "sandbox") return sandboxEndpoint;
  throw new Error("APPLE_SERVER_API_ENVIRONMENT must be production or sandbox");
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function main() {
  const jwt = authorizationToken();
  const base = endpoint();
  const requested = await appleRequest(`${base}/inApps/v1/notifications/test`, jwt);
  const token = requested.testNotificationToken;
  if (typeof token !== "string" || token.length === 0) {
    throw new Error("Apple API response did not include a test notification token");
  }

  for (let attempt = 1; attempt <= pollAttempts; attempt += 1) {
    await sleep(pollIntervalMs);
    try {
      const status = await appleRequest(`${base}/inApps/v1/notifications/test/${encodeURIComponent(token)}`, jwt);
      const results = Array.isArray(status.sendAttempts)
        ? status.sendAttempts.map((entry) => entry?.sendAttemptResult).filter(Boolean)
        : [];

      if (results.includes("SUCCESS")) {
        console.log(`apple_notification_delivery_smoke result=SUCCESS attempts=${results.length}`);
        return;
      }

      if (results.length > 0) {
        console.log(`apple_notification_delivery_smoke result=${results.at(-1)} attempts=${results.length}`);
        process.exitCode = 1;
        return;
      }
    } catch (error) {
      if (attempt === pollAttempts || !String(error.message).includes("http=404")) throw error;
    }
  }

  throw new Error(`Apple did not publish a test delivery result after ${pollAttempts} polls`);
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  test("base64url and endpoint helpers behave without hitting the network", () => {
    assert.equal(base64url("hi"), Buffer.from("hi").toString("base64url"));
    const original = process.env.APPLE_SERVER_API_ENVIRONMENT;
    try {
      delete process.env.APPLE_SERVER_API_ENVIRONMENT;
      assert.equal(endpoint(), productionEndpoint);
      process.env.APPLE_SERVER_API_ENVIRONMENT = "sandbox";
      assert.equal(endpoint(), sandboxEndpoint);
      process.env.APPLE_SERVER_API_ENVIRONMENT = "nonsense";
      assert.throws(() => endpoint(), /production or sandbox/);
    } finally {
      if (original === undefined) delete process.env.APPLE_SERVER_API_ENVIRONMENT;
      else process.env.APPLE_SERVER_API_ENVIRONMENT = original;
    }
  });
} else if (invokedAsEntrypoint) {
  main().catch((error) => {
    console.error(`apple_notification_delivery_smoke failed: ${error.message}`);
    process.exitCode = 1;
  });
}
