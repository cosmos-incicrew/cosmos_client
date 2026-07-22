import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_shell.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/pixel_button.dart';
import '../../data/profile_store.dart';
import '../../data/skin_concern.dart';

/// 온보딩 · 피부고민 선택 — 모공/미백/주름 등 다중 선택.
/// (피그마: 피부고민 칩 선택 → NEXT)
/// 다음 단계는 등록 완료 화면(BSTI vs 홈 선택).
///
/// 프로필 등록 화면에도 같은 선택이 있다 — 이 화면은 고민만 다시 고르는
/// 단독 단계로, 저장은 프로필 저장소(서버 연동)를 그대로 쓴다.
class SkinConcernScreen extends ConsumerStatefulWidget {
  const SkinConcernScreen({super.key});

  @override
  ConsumerState<SkinConcernScreen> createState() => _SkinConcernScreenState();
}

class _SkinConcernScreenState extends ConsumerState<SkinConcernScreen> {
  late final Set<SkinConcern> _selected = {
    // 이미 프로필에 저장된 고민이 있으면 채워서 시작한다.
    ...ref.read(userProfileProvider).concerns,
  };

  Future<void> _next() async {
    final store = ref.read(userProfileProvider.notifier);
    // 서버 저장은 전체 덮어쓰기 — 고민만 바꾼 전체 프로필을 올린다.
    await store.save(
      ref.read(userProfileProvider).copyWith(concerns: {..._selected}),
    );
    if (mounted) context.push('/onboarding/done');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text('피부고민을 골라주세요',
                    style: AppTextStyles.headline),
                const SizedBox(height: 8),
                Text('여러 개 골라도 돼요. 추천에 반영됩니다.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in SkinConcern.values) _chip(c),
                  ],
                ),
                const Spacer(),
                PixelButton(
                  label: '다음',
                  // 안 골라도 넘어갈 수 있다 (강제하지 않음 — 프로필과 동일).
                  onPressed: _next,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(SkinConcern c) {
    final selected = _selected.contains(c);
    return GestureDetector(
      onTap: () => setState(() {
        selected ? _selected.remove(c) : _selected.add(c);
      }),
      child: PixelBox(
        borderColor: selected ? AppColors.primary : AppColors.outline,
        fillColor: selected ? AppColors.primaryLight : AppColors.surface,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          c.label,
          style: AppTextStyles.body.copyWith(
            color:
                selected ? AppColors.primaryDark : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
