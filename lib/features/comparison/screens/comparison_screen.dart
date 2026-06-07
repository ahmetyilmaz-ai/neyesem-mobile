import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/ai_api_service.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final TextEditingController _controller = TextEditingController();
  final AiApiService _aiApiService = AiApiService();

  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runCompare(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });

    try {
      final data = await _aiApiService.compare(query: trimmed, limit: 10);
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _data = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        title: const Text('Fiyat Karşılaştırma',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryOrange,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surfaceLight,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _runCompare,
                  decoration: InputDecoration(
                    hintText: 'Ör: "pizza", "tavuk döner", "waffle"...',
                    prefixIcon: const Icon(Icons.compare_arrows,
                        color: AppColors.primaryOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _runCompare(_controller.text),
                    icon: const Icon(Icons.compare_arrows,
                        color: Colors.white, size: 18),
                    label: const Text('Fiyatları Karşılaştır',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
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
    if (!_searched) {
      return _buildHint();
    }
    final data = _data ?? {};
    final analysis = data['price_analysis'];
    if (analysis is! Map) {
      return _buildEmpty();
    }

    final platformComparison = (data['platform_comparison'] is List)
        ? List<Map<String, dynamic>>.from(
            (data['platform_comparison'] as List).whereType<Map>())
        : <Map<String, dynamic>>[];
    final cheapestItems = (data['cheapest_items'] is List)
        ? List<Map<String, dynamic>>.from(
            (data['cheapest_items'] as List).whereType<Map>())
        : <Map<String, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildAnalysisCard(Map<String, dynamic>.from(analysis)),
        if (platformComparison.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Platform Karşılaştırması',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...platformComparison.map(_buildPlatformRow),
        ],
        if (cheapestItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('En Ucuz Seçenekler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...cheapestItems.take(8).map(_buildCheapestRow),
        ],
      ],
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> a) {
    final minP = _toDouble(a['min_price']);
    final maxP = _toDouble(a['max_price']);
    final avgP = _toDouble(a['avg_price']);
    final saving = _toDouble(a['saving_rate_percent']);
    final cheapest = a['cheapest_item'] is Map
        ? Map<String, dynamic>.from(a['cheapest_item'])
        : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fiyat Analizi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('En Ucuz', minP, AppColors.healthGreen),
              _stat('Ortalama', avgP, Colors.black54),
              _stat('En Pahalı', maxP, Colors.redAccent),
            ],
          ),
          if (saving != null && saving > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.healthGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'En ucuzu seçersen %${saving.toStringAsFixed(0)} tasarruf edersin',
                style: const TextStyle(
                    color: AppColors.healthGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ],
          if (cheapest['item_name'] != null) ...[
            const SizedBox(height: 12),
            Text('En ucuz: ${cheapest['item_name']}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${_platformLabel(cheapest['platform']?.toString() ?? '-')} • ${cheapest['restaurant_name'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, double? value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value == null ? '-' : '${value.toStringAsFixed(0)} TL',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPlatformRow(Map<String, dynamic> p) {
    final minP = _toDouble(p['min_price']);
    final avgP = _toDouble(p['avg_price']);
    return Card(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.storefront, color: AppColors.primaryOrange),
        title: Text(_platformLabel(p['platform']?.toString() ?? '-'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${p['item_count'] ?? 0} ürün • ort. '
            '${avgP == null ? '-' : '${avgP.toStringAsFixed(0)} TL'}'),
        trailing: Text(minP == null ? '-' : '${minP.toStringAsFixed(0)} TL',
            style: const TextStyle(
                color: AppColors.healthGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }

  Widget _buildCheapestRow(Map<String, dynamic> item) {
    final price = _toDouble(item['price']);
    return Card(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        title: Text(item['item_name']?.toString() ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${_platformLabel(item['platform']?.toString() ?? '-')} • ${item['restaurant_name'] ?? ''}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(price == null ? '-' : '${price.toStringAsFixed(0)} TL',
            style: const TextStyle(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Platformlar arası fiyat karşılaştır',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 6),
            const Text(
              'Bir ürün ya da kategori yaz; en ucuz platform, ortalama ve '
              'tasarruf oranını gör.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('Karşılaştırılacak ürün bulunamadı',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
        ],
      ),
    );
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

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
