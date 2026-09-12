# Kotlin / Android

Add `LunarApiClient.kt` to a networking module and call it from a background
dispatcher because its dependency-free transport methods are blocking:

```kotlin
val result = withContext(Dispatchers.IO) {
    LunarApiClient(BuildConfig.LUNAR_API_KEY).toLunar("2026-02-17")
}
```

Parse `result.json` with the JSON library already used by your app. Keep the
key out of resources and public source code; for high-risk mobile deployments,
proxy through your own backend because secrets inside distributed apps can
eventually be extracted.
