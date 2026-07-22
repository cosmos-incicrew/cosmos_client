import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_assets.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/pixel_box.dart';
import '../onboarding/data/profile_store.dart';
import 'bsti.dart';

/// BSTI 설문 화면 — 문항을 하나씩 풀며 보기(4개)를 선택한다.
///
/// "Q1" 같은 문항 번호는 갈무리(포인트) 서체, 나머지 텍스트는 Pretendard.
/// 모든 문항에 답하면 [BstiEngine]으로 채점 → 결과 화면으로 코드를 넘긴다.
/// 채점은 전부 프론트에서 이뤄진다(백엔드 호출 없음).
class BstiTestScreen extends ConsumerStatefulWidget {
  const BstiTestScreen({super.key});

  @override
  ConsumerState<BstiTestScreen> createState() => _BstiTestScreenState();
}

class _BstiTestScreenState extends ConsumerState<BstiTestScreen> {
  /// 문항 id → 선택한 보기의 score(1~4).
  final Map<int, int> _answers = {};

  /// 현재 문항 인덱스 (0-based).
  int _index = 0;

  List<BstiQuestion> get _questions => kBstiQuestions;
  BstiQuestion get _q => _questions[_index];
  int get _total => _questions.length;

  void _select(int score) {
    setState(() => _answers[_q.id] = score);
  }

  void _next() {
    if (_answers[_q.id] == null) return; // 미선택이면 진행 안 함
    if (_index < _total - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  void _finish() {
    final code = BstiEngine.computeCode(_answers);
    // 보고서가 읽을 수 있게 결과를 저장한다. (URL 쿼리는 화면 표시용)
    // 서버 저장은 기다리지 않는다 — 실패해도 로컬 상태는 남고, 결과 화면을
    // 네트워크 때문에 붙잡아 두면 검사 흐름이 끊긴다.
    unawaited(ref.read(userProfileProvider.notifier).saveBstiType(code));
    context.pushReplacement('/bsti/result?code=$code');
  }

  @override
  Widget build(BuildContext context) {
    final selected = _answers[_q.id];
    final progress = (_index + 1) / _total;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: _index == 0 ? () => context.pop() : _prev,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 위쪽 여백 → 진행 카운터(1/20)를 아래로.
              const SizedBox(height: 20),
              Center(
                child: Text('${_index + 1} / $_total',
                    style: AppTextStyles.caption),
              ),
              const SizedBox(height: 20),
              // 진행 바 + 진행률 위치에 달린 고양이 마커.
              _ProgressWithCat(progress: progress),
              const SizedBox(height: 44),

              // 문항 번호(갈무리) + 문항 텍스트(Pretendard).
              Text('Q${_index + 1}', style: AppTextStyles.pointLg()),
              const SizedBox(height: 16),
              Text(
                _q.text,
                style: AppTextStyles.title.copyWith(height: 1.4),
              ),
              const SizedBox(height: 32),

              // 보기 4개.
              Expanded(
                child: ListView.separated(
                  itemCount: _q.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final opt = _q.options[i];
                    final isSelected = selected == opt.score;
                    return _OptionTile(
                      label: opt.label,
                      selected: isSelected,
                      onTap: () => _select(opt.score),
                    );
                  },
                ),
              ),

              // 다음 / 결과 보기 버튼 — 아래 여백을 키워 위로 올린다.
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected == null ? null : _next,
                    child: Text(_index < _total - 1 ? '다음' : '결과 보기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 보기 하나. 선택되면 테두리·배경을 강조한다.
/// 진행바 + 진행률 위치에 얹히는 고양이 마커.
///
/// 고양이 이미지는 assets/images/bsti/icon/progress_cat.png 를 쓰고,
/// 없으면 고양이 이모지로 대체한다.
class _ProgressWithCat extends StatelessWidget {
  const _ProgressWithCat({required this.progress});

  final double progress; // 0.0 ~ 1.0

  static const double _catSize = 40;
  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // 고양이 중심이 진행률 위치에 오도록, 끝에서 안 넘치게 clamp.
        final catLeft =
            (w * progress - _catSize / 2).clamp(0.0, w - _catSize);
        return SizedBox(
          height: _catSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // 바를 세로 중앙에 배치.
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: _barHeight,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  color: AppColors.primary,
                ),
              ),
              // 진행률 위치의 고양이 — 바와 세로 중앙으로 겹치게.
              Positioned(
                left: catLeft,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Image.asset(
                    AppAssets.progressCat,
                    width: _catSize,
                    height: _catSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      '🐱',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 계단식 픽셀 테두리 박스. 선택 시 포인트색 테두리 + 픽셀 그림자.
    final borderColor = selected ? AppColors.primary : AppColors.outline;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: PixelBox(
        borderColor: borderColor,
        fillColor: selected
            ? AppColors.primaryLight.withValues(alpha: 0.35)
            : AppColors.surface,
        shadowColor: selected ? AppColors.primary : null,
        pixel: 6,
        borderWidth: 3,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // 선택 표시 — 각진 픽셀 체크박스.
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 2),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
