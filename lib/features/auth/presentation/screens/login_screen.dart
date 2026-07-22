import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

/// 시트에서 고른 소셜 종류. 애플은 v1 제외라 없다.
enum _Social { kakao, google }

/// 로그인 시트 — 직전 화면(온보딩) 위에 어둠과 함께 올라오는 모달 바텀시트.
///
/// [LoginSheet.show]로 띄운다. 별도 페이지가 아니라 뒤 화면이 비쳐 보이는 모달.
/// 구성: 소셜 원형 아이콘 2개(카카오·구글) → "또는" 구분선 →
/// "로그인 없이 시작하기" 회색 텍스트. 색/폰트는 앱 컨셉, 게스트 플로우 유지.
class LoginSheet extends ConsumerStatefulWidget {
  const LoginSheet({super.key});

  /// 현재 화면 위에 로그인 시트를 띄운다. (배경 어두워짐 + 하단에서 슬라이드업)
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const LoginSheet(),
    );
  }

  @override
  ConsumerState<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<LoginSheet> {
  /// 로그인 진행 중인 소셜. null 이면 대기 상태.
  ///
  /// 카카오는 브라우저 왕복 동안 화면에 아무 변화가 없어 사용자가 다시 누르기 쉽다.
  /// 두 번 누르면 pop 이 두 번 돌아 시트 아래 화면까지 닫힌다 — 그래서 막는다.
  _Social? _inFlight;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 시트 핸들.
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 로고 PNG가 브랜드 색 원을 포함하므로 배경 원을 겹치지 않는다.
            // (구글만 원 배경이 없어 흰 원을 깔아준다)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialCircle(
                  logo: AppAssets.kakao,
                  fallbackIcon: Icons.chat_bubble,
                  fallbackBackground: const Color(0xFFFEE500),
                  fallbackForeground: const Color(0xFF3C1E1E),
                  busy: _inFlight == _Social.kakao,
                  onTap: _inFlight != null
                      ? null
                      : () => _socialLogin(context, ref, _Social.kakao),
                ),
                const SizedBox(width: 24),
                _SocialCircle(
                  logo: AppAssets.google,
                  fallbackIcon: Icons.g_mobiledata,
                  fallbackBackground: Colors.white,
                  fallbackForeground: Colors.black87,
                  // 구글 로고는 투명 배경 → 흰 원을 깔아 통일.
                  padBackground: Colors.white,
                  busy: _inFlight == _Social.google,
                  onTap: _inFlight != null
                      ? null
                      : () => _socialLogin(context, ref, _Social.google),
                ),
              ],
            ),
            // 카카오는 브라우저 왕복이라 최대 3분까지 걸린다 — 진행 중임을 알린다.
            if (_inFlight != null) ...[
              const SizedBox(height: 16),
              const Text('로그인 중입니다…', style: AppTextStyles.caption),
            ],
            const SizedBox(height: 24),
            // "또는" 구분선.
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.outline)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('또는', style: AppTextStyles.caption),
                ),
                Expanded(child: Divider(color: AppColors.outline)),
              ],
            ),
            const SizedBox(height: 16),
            // 로그인 없이 시작하기 (게스트) → 팝업.
            // 소셜 로그인이 주(主)이므로 강조하지 않고 회색 텍스트만.
            TextButton(
              onPressed: _inFlight != null ? null : () => _guestFlow(context, ref),
              child: const Text('로그인 없이 시작하기',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  void _notice(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _notReady(BuildContext context) {
    _notice(context, '소셜 로그인은 준비 중입니다 (SDK 연동 예정)');
  }

  /// 소셜 로그인. 성공하면 시트만 닫는다 — 어디로 갈지는 라우터가 정한다
  /// (conventions.md: 인증 상태에 따른 이동은 화면에서 분기하지 않는다).
  ///
  /// 카카오는 브라우저를 거쳐 딥링크로 돌아오므로 최대 3분이 걸릴 수 있다.
  /// 실패해도 크래시 대신 안내만 띄우고 시트를 열어둔다 — 다시 시도할 수 있게.
  Future<void> _socialLogin(
    BuildContext context,
    WidgetRef ref,
    _Social social,
  ) async {
    if (_inFlight != null) return;
    setState(() => _inFlight = social);
    final ctrl = ref.read(authControllerProvider.notifier);
    // 자기 route 를 await 전에 잡아둔다 — 끝난 뒤엔 이미 사라졌을 수 있다.
    final sheetRoute = ModalRoute.of(context);
    try {
      switch (social) {
        case _Social.kakao:
          await ctrl.signInWithKakao();
        case _Social.google:
          await ctrl.signInWithGoogle();
      }
    } on AuthNotConfiguredException {
      if (context.mounted) _notReady(context);
      return;
    } on UnimplementedError {
      if (context.mounted) _notReady(context);
      return;
    } on TimeoutException {
      if (context.mounted) _notice(context, '로그인이 완료되지 않았습니다. 다시 시도해주세요.');
      return;
    } on AuthCancelledException catch (error, stackTrace) {
      // 취소는 안내를 띄우지 않는다. 로그는 남긴다 — 안 남기면 진짜 실패가
      // 취소로 위장했을 때 화면에도 로그에도 아무것도 없다.
      developer.log('소셜 로그인 취소',
          name: 'auth', error: error, stackTrace: stackTrace);
      return;
    } on Object catch (error, stackTrace) {
      // 예외 원문은 로그로만. 화면에는 한국어 고정 문구만 보여준다.
      developer.log('소셜 로그인 실패',
          name: 'auth', error: error, stackTrace: stackTrace);
      if (context.mounted) _notice(context, '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
      return;
    } finally {
      // 성공·실패·취소 어느 경로로 나가든 버튼을 다시 살린다.
      if (mounted) setState(() => _inFlight = null);
    }
    if (!context.mounted) return;
    // 로그인 성공 시 인증 스트림이 라우터를 먼저 움직여 이 시트가 사라질 수 있다.
    // 그때 그냥 pop 하면 남은 마지막 페이지가 닫혀 go_router 가 죽는다.
    if (sheetRoute?.isCurrent ?? false) Navigator.of(context).pop();
  }

  /// 게스트 팝업: "비회원은 맞춤 추천 불가. 계속?"
  /// - 홈으로: 게스트로 홈 진입 (온보딩 건너뜀)
  /// - 회원가입 계속: 프로필 등록으로
  Future<void> _guestFlow(BuildContext context, WidgetRef ref) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text(
          '비회원으로 이용시,\n맞춤형 제품추천이 불가합니다.\n\n회원가입을 계속 진행할까요?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'home'),
            child: const Text('홈으로',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'signup'),
            child: const Text('계속하기'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;

    if (choice == 'home') {
      // signInAsGuest 가 onboarded 까지 세워 발행한다 — 여기서 나눠 부르면
      // 그 사이 라우터가 온보딩으로 한 번 튕긴다.
      await ref.read(authControllerProvider.notifier).signInAsGuest();
      if (context.mounted) context.go('/home');
    } else if (choice == 'signup') {
      // 로그인 시트를 닫고 프로필 등록으로.
      Navigator.of(context).pop();
      context.push('/onboarding/profile');
    }
  }
}

/// 소셜 로그인 원형 아이콘.
///
/// 로고 PNG가 이미 브랜드 색 원을 포함하므로 로고를 원형으로 꽉 채워 보여준다.
/// - [padBackground]: 로고 배경이 투명한 경우(구글) 뒤에 깔 원 색.
/// - 로고 로드 실패 시 [fallbackBackground] 원 + [fallbackIcon]으로 대체.
class _SocialCircle extends StatelessWidget {
  const _SocialCircle({
    required this.logo,
    required this.fallbackIcon,
    required this.fallbackBackground,
    required this.fallbackForeground,
    required this.onTap,
    this.padBackground,
    this.busy = false,
  });

  static const double _size = 56;

  final String? logo;
  final IconData fallbackIcon;
  final Color fallbackBackground;
  final Color fallbackForeground;
  final Color? padBackground;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final logoPath = logo;
    // 투명 심볼 로고(구글 G)는 흰 원 + 안쪽 여백을 두고 작게.
    // 원 배경이 포함된 로고(카카오)는 원을 꽉 채운다.
    final isSymbolOnly = padBackground != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: ClipOval(
        child: SizedBox(
          width: _size,
          height: _size,
          // 진행 중인 버튼은 스피너로 바꿔 어느 쪽을 눌렀는지 보이게 한다.
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : logoPath == null
              ? _fallback()
              : ColoredBox(
                  color: padBackground ?? Colors.transparent,
                  child: Padding(
                    // 심볼 로고만 여백을 줘서 원 안에 작게 앉힌다.
                    padding: EdgeInsets.all(isSymbolOnly ? 14 : 0),
                    child: Image.asset(
                      logoPath,
                      fit: isSymbolOnly ? BoxFit.contain : BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: fallbackBackground,
      child: Icon(fallbackIcon, color: fallbackForeground, size: 26),
    );
  }
}
