import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_assets.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/pixel_box.dart';
import 'bsti.dart';

/// BSTI 결과 화면 — 유형별 고양이 + 4축 비율 + 타입 코드/페르소나 + 권장/기피 성분.
///
/// [typeCode] (예: 'OSPW')로 [kBstiSkinTypes]에서 실제 유형을 찾아 그린다.
/// 축 비율 게이지는 데모용 기본값(정확한 %는 검사 답변 연결 시 채워짐).
class BstiResultScreen extends StatelessWidget {
  const BstiResultScreen({super.key, this.typeCode = 'OSPW'});

  /// 4글자 유형 코드. 라우트에서 넘겨받는다. (기본값 = OSPW)
  final String typeCode;

  @override
  Widget build(BuildContext context) {
    final type = kBstiSkinTypes[typeCode] ?? kBstiSkinTypes['OSPW']!;
    final recommend = _resolve(type.recommend);
    final avoid = _resolve(type.avoid);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 52, 24, 32),
        children: [
          ScreenTitle(
            title: 'BSTI 결과',
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            // 재검사 — 결과를 버리고 설문을 처음부터 다시.
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
              iconSize: 24,
              tooltip: '재검사',
              onPressed: () => _retest(context),
            ),
          ),
          // 헤더: [왼쪽 고양이] + [오른쪽 "나의 피부타입은" · 코드]
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 왼쪽 고양이 — 배경 없이 이미지만.
              SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  type.catImageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.pets, size: 48),
                ),
              ),
              const SizedBox(width: 16),
              // 오른쪽 글 — 남는 폭을 채우고 넘치면 줄바꿈.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('나의 피부타입은',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    // 타입 코드 — 갈무리 대형 포인트 서체.
                    Text(type.code,
                        style: AppTextStyles.pointLg(color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 아래: 페르소나 이름 + 태그라인.
          Text(type.personaName, style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text(type.tagline,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 28),
          for (final axis in _demoAxes(type)) _axisBar(axis),
          const SizedBox(height: 24),
          _ingredientSection(
            '권장성분',
            recommend,
            AppColors.safe,
            AppAssets.iconRecommend,
          ),
          const SizedBox(height: 20),
          _ingredientSection(
            '주의성분',
            avoid,
            AppColors.danger,
            AppAssets.iconAvoid,
          ),
          const SizedBox(height: 32),
          // 화장대로 — 여기서 제품을 담아야 매칭 점수가 나온다(주 동선).
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/shelf'),
              child: const Text('내 화장대 만들러 가기'),
            ),
          ),
          const SizedBox(height: 10),
          // 홈으로 — 보조 동선이라 회색. 나가기 전에 한 번 묻는다.
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.outline,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: () => _confirmHome(context),
              child: const Text('홈으로'),
            ),
          ),
        ],
      ),
    );
  }

  /// 홈으로 — 화장대를 안 만들면 매칭 점수를 못 보므로 한 번 묻는다.
  Future<void> _confirmHome(BuildContext context) async {
    final goHome = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text(
          '내 화장대에 자주 쓰는 화장품을 등록하면\n나와의 매칭 점수를 알 수 있습니다.\n\n이대로 나가시겠습니까?',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('홈으로',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('내 화장대 만들기'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    // 팝업을 그냥 닫으면(null) 아무 데도 안 간다 — 결과 화면에 머문다.
    if (goHome == true) {
      context.go('/home');
    } else if (goHome == false) {
      context.go('/shelf');
    }
  }

  /// 재검사 — 결과가 사라지므로 한 번 묻고 설문 처음으로 보낸다.
  Future<void> _retest(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text(
          '처음부터 다시 검사할까요?\n지금 결과는 사라집니다.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('다시 검사'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    // 결과 화면을 설문으로 갈아끼운다 (뒤로가기로 결과에 못 돌아오게).
    context.pushReplacement('/bsti/test');
  }

  List<BstiIngredient> _resolve(List<BstiTypeIngredient> links) {
    final sorted = [...links]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return [
      for (final l in sorted)
        if (kBstiIngredients[l.ingredientId] != null)
          kBstiIngredients[l.ingredientId]!,
    ];
  }

  // 유형 코드에서 각 축의 극·라벨을 만들어 게이지로 보여준다.
  // (정확한 %는 검사 답변 연결 전까지 데모값 65%)
  List<_AxisView> _demoAxes(BstiSkinType t) {
    return [
      for (final axis in kBstiAxes)
        _AxisView(
          axis: axis,
          isHigh: switch (axis.code) {
            'oil' => t.oil == axis.highPole,
            'sensitivity' => t.sensitivity == axis.highPole,
            'pigment' => t.pigment == axis.highPole,
            _ => t.aging == axis.highPole,
          },
        ),
    ];
  }

  Widget _axisBar(_AxisView v) {
    final leftPercent = v.isHigh ? 65 : 35; // 데모값
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 축 라벨(지성/건성 등) — 키워서 잘 보이게.
              Text('${v.axis.highPole} ${v.axis.highLabel} $leftPercent%',
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700)),
              Text('${v.axis.lowPole} ${v.axis.lowLabel} ${100 - leftPercent}%',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: leftPercent / 100,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientSection(
    String title,
    List<BstiIngredient> items,
    Color color,
    String iconAsset,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 앞 고양이 아이콘 — 권장/주의를 한눈에.
        Row(
          children: [
            // 세로로 긴 이미지 — 높이 기준으로 키우고 가로는 비율대로.
            Image.asset(
              iconAsset,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                title == '권장성분' ? Icons.check_circle : Icons.warning,
                color: color,
                size: 48,
              ),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: AppTextStyles.title.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in items) _BitmapChip(label: i.nameKo, color: color),
          ],
        ),
      ],
    );
  }
}

/// 픽셀 느낌 성분 칩 — 계단식 픽셀 테두리 박스.
class _BitmapChip extends StatelessWidget {
  const _BitmapChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      borderColor: color,
      // 그림자 없이, 안쪽을 성분 색으로 옅게 채운다.
      fillColor: color.withValues(alpha: 0.12),
      pixel: 5,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

class _AxisView {
  const _AxisView({required this.axis, required this.isHigh});
  final BstiAxis axis;
  final bool isHigh;
}
