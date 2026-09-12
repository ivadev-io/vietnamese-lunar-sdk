# Swift / iOS

```swift
let client = LunarApiClient(apiKey: secretFromKeychain)
let response = try await client.toLunar(date: "2026-02-17")
let json = try JSONSerialization.jsonObject(with: response.data)
```

For public App Store applications, prefer a backend proxy: no secret embedded
in a distributed mobile binary can be considered permanently confidential.
