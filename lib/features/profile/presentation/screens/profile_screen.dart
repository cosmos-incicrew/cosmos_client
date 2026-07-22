import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/data/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 마이페이지. 사용자 정보 + 로그아웃.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.person,
                  size: 40, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(auth.displayName ?? '사용자',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          Center(
            child: Text(_providerLabel(auth.provider),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('내 프로필'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('찜한 제품'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('최근 본 제품'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () => _confirmSignOut(context, ref, auth),
          ),
          // 게스트는 서버에 계정이 없다 — 탈퇴할 대상이 없으므로 보여주지 않는다.
          if (auth.status == AuthStatus.authenticated) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_remove, color: AppColors.danger),
              title: const Text('회원 탈퇴',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  /// 되돌릴 수 없는 동작 앞에 한 번 묻는다.
  Future<bool> _confirm(
    BuildContext context, {
    required String message,
    required String confirmLabel,
    Color? confirmColor,
  }) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  /// 게스트는 담아둔 것이 다 사라지므로 문구를 나눈다.
  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AuthState auth,
  ) async {
    final isGuest = auth.status == AuthStatus.guest;
    final ok = await _confirm(
      context,
      message: isGuest
          ? '게스트로 이용 중입니다.\n로그아웃하면 저장한 내용이 모두 사라집니다.\n\n계속할까요?'
          : '로그아웃할까요?',
      confirmLabel: '로그아웃',
    );
    // 어디로 갈지는 라우터가 정한다 (conventions.md).
    if (ok) await ref.read(authControllerProvider.notifier).signOut();
  }

  /// 실패하면 로그아웃하지 않고 안내만 띄운다 — 탈퇴된 줄 알았는데
  /// 계정이 남아 있는 상태가 제일 나쁘다.
  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      message: '계정과 저장된 프로필·BSTI 결과가\n모두 삭제됩니다.\n\n되돌릴 수 없습니다. 탈퇴할까요?',
      confirmLabel: '탈퇴',
      confirmColor: AppColors.danger,
    );
    if (!ok) return;

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } on Object catch (error, stackTrace) {
      developer.log('회원 탈퇴 실패',
          name: 'auth', error: error, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('탈퇴에 실패했습니다. 잠시 후 다시 시도해주세요.')),
          );
      }
    }
  }

  String _providerLabel(AuthProvider provider) {
    return switch (provider) {
      AuthProvider.guest => '게스트 로그인',
      AuthProvider.kakao => '카카오 계정',
      AuthProvider.google => 'Google 계정',
      AuthProvider.apple => 'Apple 계정',
      AuthProvider.none => '',
    };
  }
}
