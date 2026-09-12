import assert from "node:assert/strict";
import test from "node:test";
import { LunarApiError, VietnameseLunarClient } from "../index.js";

test("builds a typed request and reads quota headers", async () => {
  let requested;
  const client = new VietnameseLunarClient({ apiKey: "secret", fetch: async (url, options) => {
    requested = { url, options };
    return new Response(JSON.stringify({ lunar: { day: 1, month: 1, year: 2026, isLeapMonth: false } }), {
      headers: { "Content-Type": "application/json", "X-RateLimit-Daily-Limit": "1000", "X-RateLimit-Daily-Remaining": "999", "X-RateLimit-Daily-Reset": "42" }
    });
  } });
  const result = await client.toLunar("2026-02-17");
  assert.equal(requested.url, "https://lunar.ivadev.workers.dev/v1/lunar?date=2026-02-17");
  assert.equal(requested.options.headers["X-API-Key"], "secret");
  assert.equal(result.lunar.day, 1);
  assert.deepEqual(client.lastQuota, { limit: 1000, remaining: 999, resetEpochSeconds: 42 });
});

test("does not retry quota errors", async () => {
  let calls = 0;
  const client = new VietnameseLunarClient({ apiKey: "secret", fetch: async () => {
    calls++;
    return Response.json({ error: "daily_quota_exceeded", message: "Customer daily quota reached" }, { status: 429, headers: { "Retry-After": "60" } });
  } });
  await assert.rejects(client.toLunar("2026-02-17"), (error) => error instanceof LunarApiError && error.code === "daily_quota_exceeded");
  assert.equal(calls, 1);
});
