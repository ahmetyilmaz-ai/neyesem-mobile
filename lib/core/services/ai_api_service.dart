import 'dart:convert';

import 'package:http/http.dart' as http;

class AiApiService {
  // Backend (Express) üzerinden: mobil -> backend:3000 -> AI:8000.
  // Backend aynı uçları (/homepage, /recommend, /compare, /suspicious-discounts)
  // AI'a iletir; ayrıca auth/profil sağlar. (Doğrudan AI için: 127.0.0.1:8000)
  //
  // baseUrl, sayfanın AÇILDIĞI host'tan türetilir; böylece:
  //  - PC'de Chrome ile açınca   -> localhost:3000
  //  - Telefonda LAN üzerinden    -> http://<pc-ip>:3000  (sabit IP yazmaya gerek yok)
  // Backend telefonla aynı wifi'de ve 3000'i açık olmalı (cors zaten açık).
  static String get baseUrl {
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return 'http://127.0.0.1:3000';
    }
    return 'http://$host:3000';
  }

  Future<Map<String, dynamic>> getHomepageRecommendations({
    int limit = 8,
  }) async {
    final uri = Uri.parse('$baseUrl/homepage?limit=$limit');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Homepage önerileri alınamadı: ${response.statusCode}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recommend({
    required String query,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'limit': limit,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Öneri alınamadı: ${response.statusCode}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> compare({
    required String query,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/compare');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'limit': limit,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Karşılaştırma alınamadı: ${response.statusCode}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> suspiciousDiscounts({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/suspicious-discounts?limit=$limit');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Şüpheli indirimler alınamadı: ${response.statusCode}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
