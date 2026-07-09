import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/models/product.dart';

/// 제품 상세 화면. 성분 리스트 + 안전도 표시.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    // TODO: productId 로 API 조회. 지금은 샘플에서 찾음.
    final product = sampleProducts.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(message: '제품을 찾을 수 없어요'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(product.brand)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.image_outlined,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.category != null)
                      Text(product.category!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (product.safetyScore != null)
                      _safetyBar(context, product.safetyScore!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('전성분',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.ingredients
                .map((i) => Chip(label: Text(i)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _safetyBar(BuildContext context, int score) {
    final color = score >= 85
        ? AppColors.safe
        : score >= 70
            ? AppColors.caution
            : AppColors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('성분 안전도 $score점',
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}
