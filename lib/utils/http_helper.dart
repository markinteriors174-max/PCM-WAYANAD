import 'package:http/http.dart' as http;

class HttpHelper {
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return http.get(url, headers: headers);
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return http.post(url, headers: headers, body: body);
  }

  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body}) {
    return http.patch(url, headers: headers, body: body);
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers}) {
    return http.delete(url, headers: headers);
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) {
    return http.put(url, headers: headers, body: body);
  }
}
