import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(authTokenStorageKey);

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    return _client.get(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(),
    );
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    return _client.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
  }

  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    return _client.patch(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
  }
}
