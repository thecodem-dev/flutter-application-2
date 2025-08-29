import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session.dart';

class Api {
  static const base = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:5000',
  );

  static Future<Map<String, dynamic>> post(String path, Map body) async {
    final t = await Session.token();
    final res = await http.post(
      Uri.parse('$base$path'),
      headers: {
        'Content-Type': 'application/json',
        if (t != null) 'Authorization': 'Bearer $t',
      },
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getList(String path) async {
    final t = await Session.token();
    final res = await http.get(
      Uri.parse('$base$path'),
      headers: {if (t != null) 'Authorization': 'Bearer $t'},
    );
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> postEmpty(String path) async {
    final t = await Session.token();
    final res = await http.post(
      Uri.parse('$base$path'),
      headers: {
        'Content-Type': 'application/json',
        if (t != null) 'Authorization': 'Bearer $t',
      },
    );
    return jsonDecode(res.body);
  }
}
