# Vietnamese Lunar API SDKs

Thin, open-source clients for `https://lunar.ivadev.workers.dev`. These SDKs
contain **no calendar or astronomy algorithm**: all approved calculations stay
inside the private Vietnamese Lunar Core service.

Available clients:

- `javascript/`: Node.js and TypeScript declarations.
- `kotlin/`: dependency-free JVM/Android transport client.
- `swift/`: async URLSession client for Apple platforms.
- `dart/`: Dart/Flutter server or mobile client.

The machine-readable contract is available at
[`/openapi.json`](https://lunar.ivadev.workers.dev/openapi.json).

## Credentials

Ask the service administrator for a customer `X-API-Key`. Use one key per
project and environment. Store it in server secrets, Android Keystore, iOS
Keychain, or another protected runtime store. Do not commit it or place it in
a public website bundle.

Every successful protected response includes the daily limit, remaining
requests, and next UTC reset in `X-RateLimit-Daily-*` headers. SDKs do not retry
HTTP 429 automatically, because retry loops waste quota.

## Minimal request

```sh
curl --fail-with-body \
  'https://lunar.ivadev.workers.dev/v1/lunar?date=2026-02-17' \
  -H 'X-API-Key: vnlc_your_key'
```

See each platform directory for integration notes.
