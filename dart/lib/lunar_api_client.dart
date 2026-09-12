import 'dart:convert';
import 'dart:io';

class LunarApiResponse {
  final int status;
  final Map<String, dynamic> json;
  final int? dailyLimit;
  final int? dailyRemaining;
  final int? dailyResetEpochSeconds;
  const LunarApiResponse(this.status, this.json, this.dailyLimit, this.dailyRemaining, this.dailyResetEpochSeconds);
}

class LunarApiException implements Exception {
  final int status;
  final Map<String, dynamic> json;
  const LunarApiException(this.status, this.json);
  @override String toString() => 'Vietnamese Lunar API returned HTTP $status';
}

/// Transport-only Dart/Flutter client. It contains no calendar algorithm.
class LunarApiClient {
  final String apiKey;
  final String baseUrl;
  final Duration timeout;
  final HttpClient _http;

  LunarApiClient(this.apiKey, {this.baseUrl = 'https://lunar.ivadev.workers.dev', this.timeout = const Duration(seconds: 10), HttpClient? httpClient})
      : assert(apiKey != ''), _http = httpClient ?? HttpClient();

  Future<LunarApiResponse> toLunar(String date, {String? profile}) => _get('/v1/lunar', {'date': date, if (profile != null) 'profile': profile});
  Future<LunarApiResponse> toSolar(int day, int month, int year, {bool isLeapMonth = false, String? profile}) => _get('/v1/solar', {'day': '$day', 'month': '$month', 'year': '$year', 'leap': '$isLeapMonth', if (profile != null) 'profile': profile});
  Future<LunarApiResponse> solarTerms(int year, {String? profile}) => _get('/v1/solar-terms', {'year': '$year', if (profile != null) 'profile': profile});

  Future<LunarApiResponse> toLunarBatch(List<String> dates, {String? profile}) async {
    if (dates.isEmpty || dates.length > 31) throw ArgumentError('dates must contain 1 to 31 values');
    final uri = Uri.parse(baseUrl).resolve('/v1/lunar/batch');
    final request = await _http.postUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set('X-API-Key', apiKey);
    request.headers.set('X-Client-Version', 'dart/1.0.0');
    request.write(jsonEncode({'dates': dates, if (profile != null) 'profile': profile}));
    return _read(await request.close().timeout(timeout));
  }

  Future<LunarApiResponse> _get(String path, Map<String, String> query) async {
    final uri = Uri.parse(baseUrl).resolve(path).replace(queryParameters: query);
    final request = await _http.getUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set('X-API-Key', apiKey);
    request.headers.set('X-Client-Version', 'dart/1.0.0');
    return _read(await request.close().timeout(timeout));
  }

  Future<LunarApiResponse> _read(HttpClientResponse response) async {
    final text = await utf8.decoder.bind(response).join();
    final body = text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) throw LunarApiException(response.statusCode, body);
    int? header(String name) => int.tryParse(response.headers.value(name) ?? '');
    return LunarApiResponse(response.statusCode, body, header('X-RateLimit-Daily-Limit'), header('X-RateLimit-Daily-Remaining'), header('X-RateLimit-Daily-Reset'));
  }

  void close() => _http.close();
}
