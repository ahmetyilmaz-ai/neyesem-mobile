import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/ai_api_service.dart';

class SuspiciousDiscountsScreen extends StatefulWidget {
  const SuspiciousDiscountsScreen({super.key});

  @override
  State<SuspiciousDiscountsScreen> createState() => _SuspiciousDiscountsScreenState();
}

class _SuspiciousDiscountsScreenState extends State<SuspiciousDiscountsScreen> {
  final AiApiService _aiApiService = AiApiService();
  
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _aiApiService.suspiciousDiscounts(limit: 40);
      setState(() {
        _data = data;
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
        title: const Text(
          'Sahte İndirim Dedektörü',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryOrange,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_error != null) {
      return _buildErrorState(_error!);
    }

    final data = _data ?? {};
    final itemsList = data['items'];
    final items = itemsList is List
        ? itemsList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    final totalScanned = data['total_scanned'] ?? 0;
    final suspiciousCount = data['suspicious_count'] ?? 0;

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: _loadData,
      child: Column(
        children: [
          _buildInfoBanner(totalScanned, suspiciousCount),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildSuspiciousCard(items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(dynamic scanned, dynamic suspicious) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: Colors.amber.shade800, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yapay Zeka Analiz Raporu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toplam taranan ürün: $scanned | Tespit edilen şüpheli fiyatlandırma: $suspicious',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspiciousCard(Map<String, dynamic> item) {
    final itemName = item['item_name']?.toString() ?? '-';
    final restaurantName = item['restaurant_name']?.toString() ?? '-';
    final platform = item['platform']?.toString() ?? '-';
    final category = item['category']?.toString() ?? '-';
    final price = _toDouble(item['price']);
    final originalPrice = _toDouble(item['original_price']);
    final discountRate = _toDouble(item['discount_rate']);
    final score = _toDouble(item['suspicion_score']) ?? 0.0;
    final medianPrice = _toDouble(item['category_median_price']);
    final reasons = (item['reasons'] as List?)?.map((e) => e.toString()).toList() ?? [];

    Color scoreColor = Colors.orange;
    String scoreText = 'Şüpheli';
    if (score >= 3.0) {
      scoreColor = Colors.red.shade700;
      scoreText = 'Kritik';
    } else if (score >= 2.0) {
      scoreColor = Colors.orange.shade800;
      scoreText = 'Yüksek';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBadge(
                      text: _platformLabel(platform),
                      textColor: AppColors.partnerBlue,
                      bgColor: AppColors.partnerBlue.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      text: category,
                      textColor: Colors.grey.shade700,
                      bgColor: Colors.grey.shade100,
                    ),
                    const Spacer(),
                    _buildBadge(
                      text: '$scoreText (${score.toStringAsFixed(1)})',
                      textColor: Colors.white,
                      bgColor: scoreColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurantName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'İndirimli Fiyat',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          price == null ? '-' : '${price.toStringAsFixed(0)} TL',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    if (originalPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gösterilen Eski',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            '${originalPrice.toStringAsFixed(0)} TL',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 16),
                    if (medianPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kategori Medyanı',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            '${medianPrice.toStringAsFixed(0)} TL',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    if (discountRate != null && discountRate > 0)
                      _buildBadge(
                        text: '-%${discountRate.toStringAsFixed(0)}',
                        textColor: AppColors.healthGreen,
                        bgColor: AppColors.healthGreen.withValues(alpha: 0.1),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (reasons.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.red.shade100, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Şüpheli İndirim Nedenleri:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...reasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade950,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.red,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rapor alınamadı.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tekrar Dene',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_rounded,
              color: AppColors.healthGreen,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Şüpheli İndirim Bulunmadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Harika! Veri tabanındaki tüm indirimli ürünler gerçeğe uygun görünüyor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
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
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
