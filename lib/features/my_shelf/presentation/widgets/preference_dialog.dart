import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/shelf_preference.dart';

/// 검색 결과를 눌렀을 때 뜨는 선호/기피 선택 팝업.
///
/// 검색한 종류에 따라 문구가 달라진다.
///   제품 → "선호 제품으로 추가" / "기피 제품으로 추가" / "취소"
///   성분 → "선호 성분으로 추가" / "기피 성분으로 추가" / "취소"
///
/// 선택하면 [PreferenceKind]를, 취소하면 null 을 돌려준다.
Future<PreferenceKind?> showPreferenceDialog(
  BuildContext context, {
  required String name,
  required bool isProduct,
}) {
  final what = isProduct ? '제품' : '성분';

  return showDialog<PreferenceKind>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        name,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
      content: const Text(
        '내 화장대에 어떻게 담을까요?',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption,
      ),
      // 버튼이 길어 세로로 쌓는다. 취소는 맨 아래.
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        _actionButton(
          label: '선호 $what으로 추가',
          background: AppColors.safe,
          onTap: () => Navigator.pop(ctx, PreferenceKind.like),
        ),
        const SizedBox(height: 8),
        _actionButton(
          label: '기피 $what으로 추가',
          background: AppColors.danger,
          onTap: () => Navigator.pop(ctx, PreferenceKind.dislike),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('취소',
              style: AppTextStyles.button
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ],
    ),
  );
}

Widget _actionButton({
  required String label,
  required Color background,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: AppTextStyles.button),
    ),
  );
}
