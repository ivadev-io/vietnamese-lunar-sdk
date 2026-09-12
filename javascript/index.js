const DEFAULT_BASE_URL = "https://lunar.ivadev.workers.dev";

export class LunarApiError extends Error {
  constructor(message, options = {}) {
    super(message);
    this.name = "LunarApiError";
    this.status = options.status;
    this.code = options.code;
    this.retryAfter = options.retryAfter;
    this.quota = options.quota;
  }
}

function integerHeader(headers, name) {
  const value = headers.get(name);
  return value === null ? null : Number(value);
}

function quotaFrom(headers) {
  const limit = integerHeader(headers, "X-RateLimit-Daily-Limit");
  if (limit === null) return null;
  return {
    limit,
    remaining: integerHeader(headers, "X-RateLimit-Daily-Remaining"),
    resetEpochSeconds: integerHeader(headers, "X-RateLimit-Daily-Reset")
  };
}

export class VietnameseLunarClient {
  constructor({ apiKey, baseUrl = DEFAULT_BASE_URL, fetch: fetchImplementation = globalThis.fetch, timeoutMs = 10000, allowBrowser = false } = {}) {
    if (!apiKey || typeof apiKey !== "string") throw new TypeError("apiKey is required");
    if (typeof window !== "undefined" && !allowBrowser) throw new Error("Do not expose an API key in browser code; call from your backend");
    if (typeof fetchImplementation !== "function") throw new TypeError("A fetch implementation is required");
    this.apiKey = apiKey;
    this.baseUrl = baseUrl.replace(/\/$/, "");
    this.fetch = fetchImplementation;
    this.timeoutMs = timeoutMs;
    this.lastQuota = null;
  }

  async request(path, options = {}) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    let response;
    try {
      response = await this.fetch(`${this.baseUrl}${path}`, {
        ...options,
        signal: controller.signal,
        headers: { Accept: "application/json", "X-API-Key": this.apiKey, "X-Client-Version": "js/1.0.0", ...options.headers }
      });
    } catch (error) {
      throw new LunarApiError(error.name === "AbortError" ? "Vietnamese Lunar API request timed out" : error.message);
    } finally {
      clearTimeout(timer);
    }
    this.lastQuota = quotaFrom(response.headers);
    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new LunarApiError(body.message || body.error || `HTTP ${response.status}`, {
        status: response.status,
        code: body.error,
        retryAfter: integerHeader(response.headers, "Retry-After"),
        quota: this.lastQuota
      });
    }
    return body;
  }

  toLunar(date, profile) {
    const query = new URLSearchParams({ date });
    if (profile) query.set("profile", profile);
    return this.request(`/v1/lunar?${query}`);
  }

  toSolar({ day, month, year, isLeapMonth = false, profile }) {
    const query = new URLSearchParams({ day: String(day), month: String(month), year: String(year), leap: String(isLeapMonth) });
    if (profile) query.set("profile", profile);
    return this.request(`/v1/solar?${query}`);
  }

  solarTerms(year, profile) {
    const query = new URLSearchParams({ year: String(year) });
    if (profile) query.set("profile", profile);
    return this.request(`/v1/solar-terms?${query}`);
  }

  toLunarBatch(dates, profile) {
    return this.request("/v1/lunar/batch", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ dates, ...(profile ? { profile } : {}) })
    });
  }
}
