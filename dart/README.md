# Dart / Flutter

```dart
final client = LunarApiClient(apiKeyFromSecureStorage);
final result = await client.toLunar('2026-02-17');
print(result.json);
client.close();
```

This `dart:io` client targets mobile and server apps, not Flutter Web. Prefer a
backend proxy when a mobile application must keep the key strongly protected.
