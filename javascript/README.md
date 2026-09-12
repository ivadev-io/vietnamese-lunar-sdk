# JavaScript / TypeScript

```js
import { VietnameseLunarClient } from "@ivadev/vietnamese-lunar-api";

const lunar = new VietnameseLunarClient({ apiKey: process.env.LUNAR_API_KEY });
console.log(await lunar.toLunar("2026-02-17"));
console.log(lunar.lastQuota);
```

This package blocks browser use by default to prevent embedding customer keys
in public bundles. Web applications should call it from their own backend.
