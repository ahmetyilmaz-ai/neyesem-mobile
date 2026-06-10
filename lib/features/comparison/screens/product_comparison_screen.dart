import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/ai_api_service.dart';

/// Tek bir ürünün platformlar arası karşılaştırması.
/// Keşif'te bir ürüne tıklanınca açılır; aynı ürün hem Getir hem Trendyol'da
/// varsa fiyatlarını yan yana gösterir (boyut-duyarlı eşleşme AI tarafında yapılır).
class ProductComparisonScreen extends StatefulWidget {
  final String productName;

  const ProductComparisonScreen({super.key, required this.productName});

  @override
  State<ProductComparisonScreen> createState() =>
      _ProductComparisonScreenState();
}

class _ProductComparisonScreenState extends State<ProductComparisonScreen> {
  final AiApiService _aiApiService = AiApiService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _match; // ürüne en çok uyan karşılaştırma grubu
  List<Map<String, dynamic>> _others = []; // diğer yakın karşılaştırmalar

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await _aiApiService.compare(query: widget.productName, limit: 12);
      final groups = (data['cross_platform_comparisons'] is List)
          ? List<Map<String, dynamic>>.from(
              (data['cross_platform_comparisons'] as List).whereType<Map>())
          : <Map<String, dynamic>>[];

      // Tıklanan ürüne en çok benzeyen grubu seç (token örtüşmesi).
      final wanted = _tokens(widget.productName);
      Map<String, dynamic>? best;
      double bestScore = 0;
      for (final g in groups) {
        final score = _overlap(wanted, _tokens(g['group_name']?.toString()));
        if (score > bestScore) {
          bestScore = score;
          best = g;
        }
      }

      setState(() {
        _match = bestScore >= 0.34 ? best : null;
        _others = groups
            .where((g) => g != _match)
            .take(_match == null ? 8 : 5)
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        title: const Text('Ürün Karşılaştırma',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryOrange,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }
    if (_error != null) {
      return _buildError(_error!);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(widget.productName,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (_match != null)
          const Text('Bu ürün birden fazla platformda bulundu 👇',
              style: TextStyle(fontSize: 13, color: Colors.grey))
        else
          const Text(
              'Bu ürünün birebir eşi diğer platformda bulunamadı. '
              'İlgili karşılaştırmalar aşağıda.',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 16),
        if (_match != null) _buildComparisonCard(_match!, highlight: true),
        if (_others.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(_match != null ? 'Benzer ürünler' : 'İlgili karşılaştırmalar',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._others.map((g) => _buildComparisonCard(g, highlight: false)),
        ],
        if (_match == null && _others.isEmpty) _buildEmpty(),
      ],
    );
  }

  Widget _buildComparisonCard(Map<String, dynamic> group,
      {required bool highlight}) {
    final prices = (group['platform_prices'] is List)
        ? List<Map<String, dynamic>>.from(
            (group['platform_prices'] as List).whereType<Map>())
        : <Map<String, dynamic>>[];
    final saving = _toDouble(group['saving_rate_percent']);
    final cheapestPlatform = group['cheapest_platform']?.toString();

    return Card(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: highlight
            ? const BorderSide(color: AppColors.primaryOrange, width: 1.5)
            : BorderSide.none,
      ),
      elevation: highlight ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(group['group_name']?.toString() ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (saving != null && saving > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.healthGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('%${saving.toStringAsFixed(0)} fark',
                        style: const TextStyle(
                            color: AppColors.healthGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ...prices.map((p) => _buildPlatformPriceRow(
                  p,
                  isCheapest: p['platform']?.toString() == cheapestPlatform,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformPriceRow(Map<String, dynamic> p,
      {required bool isCheapest}) {
    final price = _toDouble(p['price']);
    final platform = p['platform']?.toString() ?? '-';
    final restaurant = p['restaurant_name']?.toString() ?? '';
    final url = p['product_url']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_platformIcon(platform),
              size: 18,
              color: isCheapest ? AppColors.healthGreen : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_platformLabel(platform),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isCheapest
                                ? AppColors.healthGreen
                                : Colors.black87)),
                    if (isCheapest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.healthGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('EN UCUZ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                if (restaurant.isNotEmpty)
                  Text(restaurant,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(price == null ? '-' : '${price.toStringAsFixed(0)} TL',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCheapest
                      ? AppColors.healthGreen
                      : AppColors.primaryOrange)),
          if (url != null && url.isNotEmpty)
            IconButton(
              tooltip: 'Platformda Aç',
              icon: const Icon(Icons.open_in_new,
                  size: 18, color: AppColors.primaryOrange),
              onPressed: () => _openUrl(url),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('Bu ürün için karşılaştırma bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Karşılaştırma yapılamadı.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange),
              child: const Text('Tekrar Dene',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- yardımcılar ---

  Set<String> _tokens(String? text) {
    if (text == null) return {};
    var t = text.toLowerCase();
    const map = {
      'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c'
    };
    map.forEach((k, v) => t = t.replaceAll(k, v));
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return t
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toSet();
  }

  double _overlap(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final inter = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0 : inter / union;
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'getir_yemek':
        return Icons.delivery_dining;
      case 'trendyol':
        return Icons.shopping_bag;
      default:
        return Icons.storefront;
    }
  }

  String _platformLabel(String platform) {
    switch (platform) {
      case 'getir_yemek':
        return 'Getir Yemek';
      case 'trendyol':
        return 'Trendyol';
      case 'yemeksepeti':
        return 'Yemeksepeti';
      default:
        return platform;
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
