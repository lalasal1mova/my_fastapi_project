import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = "http://192.168.0.101:8000";

Map<String, String> authHeaders(String token) => {
  "Authorization": "Bearer $token",
  "Content-Type": "application/json",
};

Map<String, String> basicHeaders() => {
  "Content-Type": "application/json",
};

// TOKEN
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("token");
}

Future<String?> getRol() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("rol");
}

Future<String?> getUsername() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("username");
}

// LOGIN
Future<Map?> login(String username, String password) async {
  final res = await http.post(
    Uri.parse("$baseUrl/login"),
    headers: basicHeaders(),
    body: jsonEncode({"username": username, "password": password}),
  );
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", data["access_token"]);
    await prefs.setString("rol", data["rol"]);
    await prefs.setString("username", data["username"]);
    return data;
  }
  return null;
}

// VƏZİFƏLƏR
Future<List> getVezifeler() async {
  final token = await getToken();
  final res = await http.get(
    Uri.parse("$baseUrl/vezifeler"),
    headers: authHeaders(token!),
  );
  if (res.statusCode == 200) return jsonDecode(res.body);
  return [];
}

Future<void> addVezife(String ad) async {
  final token = await getToken();
  await http.post(
    Uri.parse("$baseUrl/vezifeler"),
    headers: authHeaders(token!),
    body: jsonEncode({"ad": ad}),
  );
}

Future<void> updateVezife(int id, String ad) async {
  final token = await getToken();
  await http.put(
    Uri.parse("$baseUrl/vezifeler/$id"),
    headers: authHeaders(token!),
    body: jsonEncode({"ad": ad}),
  );
}

Future<void> deleteVezife(int id) async {
  final token = await getToken();
  await http.delete(
    Uri.parse("$baseUrl/vezifeler/$id"),
    headers: authHeaders(token!),
  );
}

// İŞÇİLƏR
Future<List> getIsciler(int vezifeId) async {
  final token = await getToken();
  final res = await http.get(
    Uri.parse("$baseUrl/vezifeler/$vezifeId/isciler"),
    headers: authHeaders(token!),
  );
  if (res.statusCode == 200) return jsonDecode(res.body);
  return [];
}

Future<Map?> getIsci(int isciId) async {
  final token = await getToken();
  final res = await http.get(
    Uri.parse("$baseUrl/isciler/$isciId"),
    headers: authHeaders(token!),
  );
  if (res.statusCode == 200) return jsonDecode(res.body);
  return null;
}

Future<void> addIsci(Map<String, dynamic> data) async {
  final token = await getToken();
  await http.post(
    Uri.parse("$baseUrl/isciler"),
    headers: authHeaders(token!),
    body: jsonEncode(data),
  );
}

Future<void> updateIsci(int id, Map<String, dynamic> data) async {
  final token = await getToken();
  await http.put(
    Uri.parse("$baseUrl/isciler/$id"),
    headers: authHeaders(token!),
    body: jsonEncode(data),
  );
}

Future<void> deleteIsci(int id) async {
  final token = await getToken();
  await http.delete(
    Uri.parse("$baseUrl/isciler/$id"),
    headers: authHeaders(token!),
  );
}

// İSTİFADƏÇİLƏR
Future<List> getIstifadeciler() async {
  final token = await getToken();
  final res = await http.get(
    Uri.parse("$baseUrl/istifadeciler"),
    headers: authHeaders(token!),
  );
  if (res.statusCode == 200) return jsonDecode(res.body);
  return [];
}

Future<void> addIstifadeci(String username, String password, String rol) async {
  final token = await getToken();
  await http.post(
    Uri.parse("$baseUrl/istifadeciler"),
    headers: authHeaders(token!),
    body: jsonEncode({"username": username, "password": password, "rol": rol}),
  );
}

Future<void> deleteIstifadeci(int id) async {
  final token = await getToken();
  await http.delete(
    Uri.parse("$baseUrl/istifadeciler/$id"),
    headers: authHeaders(token!),
  );
}