import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// 로그인 화면.
///
/// 게스트 로그인만 실제 동작하고, 소셜 로그인 버튼은 UI 뼈대만 배치했습니다.
/// (탭하면 "준비 중" 스낵바 표시)
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 로고 영역
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.spa_outlined,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text('cosmos',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      )),
              const SizedBox(height: 8),
              Text('성분으로 찾는 나만의 화장품',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      )),
              const Spacer(flex: 3),

              // 소셜 로그인 버튼들 (UI 뼈대)
              _SocialButton(
                label: '카카오로 시작하기',
                icon: Icons.chat_bubble,
                background: const Color(0xFFFEE500),
                foreground: const Color(0xFF3C1E1E),
                onTap: () => _notReady(context),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: '네이버로 시작하기',
                icon: Icons.check_circle,
                background: const Color(0xFF03C75A),
                foreground: Colors.white,
                onTap: () => _notReady(context),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Google로 시작하기',
                icon: Icons.g_mobiledata,
                background: Colors.white,
                foreground: Colors.black87,
                bordered: true,
                onTap: () => _notReady(context),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Apple로 시작하기',
                icon: Icons.apple,
                background: Colors.black,
                foreground: Colors.white,
                onTap: () => _notReady(context),
              ),

              const SizedBox(height: 20),
              // 로그인 없이 시작하기 (게스트 — 실제 동작)
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signInAsGuest(),
                child: const Text('로그인 없이 시작하기',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  void _notReady(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('소셜 로그인은 준비 중입니다 (SDK 연동 예정)')),
      );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.bordered = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: foreground),
        label: Text(label, style: TextStyle(color: foreground)),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: bordered
                ? const BorderSide(color: Color(0xFFE0E0E0))
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
