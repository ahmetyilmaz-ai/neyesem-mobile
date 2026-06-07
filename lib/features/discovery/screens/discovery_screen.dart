import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/ai_api_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AiApiService _aiApiService = AiApiService();

  // Sıralama kriterleri (FR-SRCH-003) — AI sonuçları üzerinde çalışır.
  String _selectedSort = 'AI Skoru';
  final List<String> _sortOptions = [
    'AI Skoru',
    'Fiyat (Artan)',
    'Fiyat (Azalan)',
    'Restoran Puanı',
  ];

  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });

    try {
      final data = await _aiApiService.recommend(query: trimmed, limit: 20);
      final results = _parseResults(data);
      setState(() {
        _results = results;
        _loading = false;
      });
      _applySort();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _results = [];
      });
    }
  }

  // /recommend cevabını (oneriler -> {urun, restoran, ai, ...}) düz bir listeye çevirir.
  List<Map<String, dynamic>> _parseResults(Map<String, dynamic> data) {
    final raw = data['oneriler'] ?? data['recommendations'];
    if (raw is! List) {
      return [];
    }

    final List<Map<String, dynamic>> out = [];
    for (final entry in raw.whereType<Map>()) {
      final item = Map<String, dynamic>.from(entry);
      final urun = item['urun'] is Map
          ? Map<String, dynamic>.from(item['urun'])
          : <String, dynamic>{};
      final restoran = item['restoran'] is Map
          ? Map<String, dynamic>.from(item['restoran'])
          : <String, dynamic>{};
      final ai = item['ai'] is Map
          ? Map<String, dynamic>.from(item['ai'])
          : <String, dynamic>{};

      out.add({
        'title': urun['ad']?.toString() ?? '-',
        'restaurant': restoran['ad']?.toString() ?? '-',
        'price': _toDouble(urun['fiyat']),
        'original_price': _toDouble(urun['orijinal_fiyat']),
        'discount': _toDouble(urun['indirim_yuzdesi']),
        'rating': _toDouble(restoran['puan']),
        'platform': urun['en_ucuz_platform']?.toString(),
        'platform_count': urun['platform_sayisi'],
        'score': _toDouble(ai['skor']),
        'reason': ai['neden']?.toString(),
      });
    }
    return out;
  }

  void _applySort() {
    setState(() {
      if (_selectedSort == 'Fiyat (Artan)') {
        _results.sort((a, b) => (_toDouble(a['price']) ?? 1e9)
            .compareTo(_toDouble(b['price']) ?? 1e9));
      } else if (_selectedSort == 'Fiyat (Azalan)') {
        _results.sort((a, b) => (_toDouble(b['price']) ?? -1)
            .compareTo(_toDouble(a['price']) ?? -1));
      } else if (_selectedSort == 'Restoran Puanı') {
        _results.sort((a, b) => (_toDouble(b['rating']) ?? -1)
            .compareTo(_toDouble(a['rating']) ?? -1));
      } else {
        _results.sort((a, b) => (_toDouble(b['score']) ?? -1)
            .compareTo(_toDouble(a['score']) ?? -1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        title: const Text('Keşif ve Arama',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryOrange,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surfaceLight,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _runSearch,
                  decoration: InputDecoration(
                    hintText: 'Ör: "ucuz doyurucu tavuk", "yüksek proteinli"...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primaryOrange),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _results = [];
                                _searched = false;
                                _error = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryOrange),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _runSearch(_searchController.text),
                    icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    label: const Text('AI ile Ara',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sıralama:',
                        style: TextStyle(
                            color: Colors.black54, fontWeight: FontWeight.w500)),
                    DropdownButton<String>(
                      value: _selectedSort,
                      icon: const Icon(Icons.swap_vert_rounded,
                          color: AppColors.primaryOrange),
                      underline: Container(height: 1, color: Colors.transparent),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedSort = newValue);
                          _applySort();
                        }
                      },
                      items: _sortOptions
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                    ),
                  ],
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
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }
    if (_error != null) {
      return _buildErrorState(_error!);
    }
    if (!_searched) {
      return _buildHintState();
    }
    if (_results.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildSearchResultCard(_results[index]),
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> item) {
    final price = _toDouble(item['price']);
    final originalPrice = _toDouble(item['original_price']);
    final discount = _toDouble(item['discount']);
    final rating = _toDouble(item['rating']);
    final hasDiscount = discount != null && discount > 0;

    return Card(
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item['title'].toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text(price == null ? '-' : '${price.toStringAsFixed(0)} TL',
                    style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Text(item['restaurant'].toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (rating != null) ...[
                  Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 2),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                ],
                if (item['platform'] != null) ...[
                  const Icon(Icons.storefront, size: 14, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text(_platformLabel(item['platform'].toString()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 12),
                ],
                if (hasDiscount)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.healthGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('%${discount.toStringAsFixed(0)} indirim',
                        style: const TextStyle(
                            color: AppColors.healthGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (originalPrice != null && price != null && originalPrice > price) ...[
              const SizedBox(height: 4),
              Text('${originalPrice.toStringAsFixed(0)} TL',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough)),
            ],
            if (item['reason'] != null) ...[
              const SizedBox(height: 8),
              Text(item['reason'].toString(),
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHintState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('AI destekli arama',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 6),
            const Text(
              'Doğal dille yaz: "spordan çıktım yüksek proteinli ucuz bir şey", '
              '"hafif sağlıklı", "tatlı bir şey"...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
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
            const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Arama yapılamadı.',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _runSearch(_searchController.text),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('Aramanızla Eşleşen Sonuç Bulunamadı',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 4),
          const Text('Farklı kelimeler aramayı deneyin.',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
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
