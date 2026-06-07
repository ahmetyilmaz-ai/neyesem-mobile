import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/ai_api_service.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../profile/bloc/profile_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AiApiService _aiApiService = AiApiService();

  late Future<Map<String, dynamic>> _homepageFuture;

  @override
  void initState() {
    super.initState();
    _homepageFuture = _aiApiService.getHomepageRecommendations(limit: 8);
  }

  void _refreshRecommendations() {
    setState(() {
      _homepageFuture = _aiApiService.getHomepageRecommendations(limit: 8);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        title: const Text(
          'NeYesem',
          style: TextStyle(
            color: AppColors.primaryOrange,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshRecommendations,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoadingState) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            );
          }

          String userDiet = 'Standart';
          List<String> userAllergies = [];

          if (state is ProfileLoadedState) {
            userDiet = state.currentDiet;
            userAllergies = state.currentAllergies;
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: _homepageFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryOrange,
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final data = snapshot.data ?? {};
              final sections = _parseSections(data);

              return RefreshIndicator(
                color: AppColors.primaryOrange,
                onRefresh: () async {
                  _refreshRecommendations();
                  await _homepageFuture;
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Merhaba 👋',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profiliniz: $userDiet Diyet | ${userAllergies.length} Aktif Alerjen',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI destekli öneriler gerçek ürün verileri üzerinden listelenir.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (sections.isEmpty)
                      _buildEmptyState()
                    else
                      ...sections.map(_buildSection),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _parseSections(Map<String, dynamic> data) {
    final rawSections = data['sections'];

    if (rawSections is! List) {
      return [];
    }

    return rawSections
        .whereType<Map>()
        .map((section) => Map<String, dynamic>.from(section))
        .toList();
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final title = section['title']?.toString() ?? 'Öneriler';
    final description = section['description']?.toString() ?? '';
    final rawItems = section['items'];

    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...items.map((item) => _buildRecommendationCard(item, title)),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildRecommendationCard(
    Map<String, dynamic> item,
    String sectionTitle,
  ) {
    final platform = item['platform']?.toString() ?? '-';
    final restaurantName = item['restaurant_name']?.toString() ?? '-';
    final itemName = item['item_name']?.toString() ?? '-';
    final price = _toDouble(item['price']);
    final originalPrice = _toDouble(item['original_price']);
    final discountRate = _toDouble(item['discount_rate']);
    final score = _toDouble(item['score']);

    final hasDiscount = discountRate != null && discountRate > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTag(
                  text: _platformLabel(platform),
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(width: 8),
                if (hasDiscount)
                  _buildTag(
                    text: '%${discountRate.toStringAsFixed(0)} indirim',
                    color: AppColors.healthGreen,
                  ),
                const Spacer(),
                if (score != null)
                  Text(
                    'Skor ${score.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              itemName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              restaurantName,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price == null ? '-' : '${price.toStringAsFixed(0)} TL',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 8),
                if (originalPrice != null &&
                    price != null &&
                    originalPrice > price)
                  Text(
                    '${originalPrice.toStringAsFixed(0)} TL',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                const Spacer(),
                Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
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
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'AI önerileri alınamadı.',
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
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _refreshRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Şimdilik öneri bulunamadı.',
          textAlign: TextAlign.center,
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
