import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Android emulator reaches the host machine at 10.0.2.2.
/// Override: flutter run --dart-define=API_URL=http://192.168.1.5:8000
class ApiService {
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
  static String? token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic _decode(http.Response r) {
    if (r.statusCode >= 400) {
      throw Exception('Request failed (${r.statusCode}): ${r.body}');
    }
    return jsonDecode(r.body);
  }

  static Future<dynamic> get(String path) async =>
      _decode(await http.get(Uri.parse('$baseUrl$path'), headers: _headers));

  static Future<dynamic> post(String path, Map<String, dynamic> body) async =>
      _decode(await http.post(Uri.parse('$baseUrl$path'),
          headers: _headers, body: jsonEncode(body)));

  // --- auth ---
  static Future<String> sendOtp(String phone) async =>
      (await post('/auth/send-otp', {'phone': phone}))['demo_otp'] as String;

  static Future<void> verifyOtp(String phone, String otp) async {
    final res = await post('/auth/verify-otp', {'phone': phone, 'otp': otp});
    token = res['token'] as String;
  }

  // --- bills ---
  static Future<Map<String, dynamic>> uploadBill(Uint8List bytes, String filename) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/bills/upload'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final res = await http.Response.fromStream(await req.send());
    return _decode(res) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> bills() async => await get('/bills') as List<dynamic>;
  static Future<Map<String, dynamic>> forecast() async =>
      await get('/bills/forecast') as Map<String, dynamic>;

  // --- retail ---
  static Future<List<dynamic>> refills() async => await get('/retail/refills') as List<dynamic>;
  static Future<Map<String, dynamic>> order(String medicine, int qty) async =>
      await post('/retail/order', {'medicine': medicine, 'qty': qty}) as Map<String, dynamic>;

  // --- claims ---
  static Future<Map<String, dynamic>> checkClaim(Map<String, dynamic> body) async =>
      await post('/claims/check', body) as Map<String, dynamic>;

  // --- finance ---
  static Future<Map<String, dynamic>> offers(int billId) async =>
      await get('/finance/offers/$billId') as Map<String, dynamic>;
  static Future<Map<String, dynamic>> acceptOffer(Map<String, dynamic> body) async =>
      await post('/finance/accept', body) as Map<String, dynamic>;
  static Future<Map<String, dynamic>> savings() async =>
      await get('/finance/savings') as Map<String, dynamic>;
  static Future<Map<String, dynamic>> contribute(double amount) async =>
      await post('/finance/savings/contribute', {'amount': amount}) as Map<String, dynamic>;
}
