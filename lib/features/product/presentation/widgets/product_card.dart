import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/product.dart';

/// 리스트/그리드에서 재사용하는 제품 카드.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _thumbnail(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(product.ingredients.take(3).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (product.safetyScore != null) _scoreBadge(product.safetyScore!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: product.imageUrl == null
            ? Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: const Icon(Icons.image_outlined,
                    color: AppColors.primary),
              )
            : CachedNetworkImage(
                imageUrl: product.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: Color(0xFFEFEFEF)),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }

  Widget _scoreBadge(int score) {
    final color = score >= 85
        ? AppColors.safe
        : score >= 70
            ? AppColors.caution
            : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$score',
          style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}
