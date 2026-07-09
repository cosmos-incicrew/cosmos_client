import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  String _providerLabel(AuthProvider provider) {
    return switch (provider) {
      AuthProvider.guest => '게스트 로그인',
      AuthProvider.kakao => '카카오 계정',
      AuthProvider.naver => '네이버 계정',
      AuthProvider.google => 'Google 계정',
      AuthProvider.apple => 'Apple 계정',
      AuthProvider.none => '',
    };
  }
}
