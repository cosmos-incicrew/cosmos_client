import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/router/app_shell.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/profile_store.dart';
import '../../data/skin_concern.dart';

/// 프로필 화면 — 닉네임 / 나이 / 성별 / 임신·수유 / 피부고민.
///
/// 두 모드로 쓴다. 입력 항목이 같아 화면을 나누지 않았다.
///  - 온보딩 등록 (`/onboarding/profile`): 저장 후 BSTI 또는 홈으로 진행
///  - 마이페이지 수정 (`/profile/edit`, [isEditing]): 저장 후 마이페이지로 복귀
///
/// 구성(목업): 상단바(햄버거·COSMOS·마이) → My Profile → 닉네임 → 나이
///            → 성별 2칸 → NEXT / HOME (수정 모드에서는 저장).
/// 폰트·색은 앱 컨셉 그대로 (작은 글씨 Pretendard, 포인트는 갈무리).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.isEditing = false});

  /// 마이페이지에서 들어온 수정 모드인지. 온보딩 진행 버튼 대신 저장 버튼을 둔다.
  final bool isEditing;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nickname = TextEditingController();
  final _age = TextEditingController();

  /// 'female' | 'male' — 아직 안 고르면 null.
  String? _gender;

  /// 임신·수유 여부 (여성 선택 시에만 묻는다).
  /// 'none' | 'pregnant' | 'nursing'
  String? _pregnancy;

  /// 선택한 피부고민 (다중 선택). 저장은 code 로 한다.
  final _concerns = <SkinConcern>{};

  @override
  void initState() {
    super.initState();
    // 프리필이 없으면 수정 화면이 빈 칸으로 열려, 저장 시 기존 값이 통째로 지워진다.
    final profile = ref.read(userProfileProvider);
    _age.text = profile.age?.toString() ?? '';
    _gender = profile.gender;
    _pregnancy = profile.pregnancy;
    _concerns.addAll(profile.concerns);
    // 카카오는 비즈 앱 전환 전이면 이름을 안 줘서 빈 값일 수 있다.
    _nickname.text =
        profile.nickname ?? ref.read(authControllerProvider).displayName ?? '';
  }

  @override
  void dispose() {
    _nickname.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 헤더가 가리키는 곳은 모두 온보딩 완료를 요구한다. 온보딩 중에는 눌러도
    // 라우터가 제자리로 되돌리므로 아예 감춘다.
    final navigable = ref.watch(authControllerProvider).onboarded;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: navigable ? const AppDrawer() : null,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        // Builder 로 감싸야 Scaffold.of 가 이 Scaffold 를 찾는다.
        leading: navigable
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu,
                      color: AppColors.textPrimary, size: 30),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              )
            : null,
        title: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Image.asset(AppAssets.logoWordmark, height: 44),
        ),
        centerTitle: true,
        actions: [
          if (navigable)
            IconButton(
              icon: const Icon(Icons.person,
                  color: AppColors.textPrimary, size: 28),
              onPressed: () => context.go('/profile'),
            ),
          const SizedBox(width: 12),
        ],
        toolbarHeight: 80,
      ),
      // 항목이 많아 스크롤. (안 그러면 작은 폰에서 넘친다)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          // 반응형: 넓은 창에서 폼이 좌우로 퍼지지 않게 폰 폭으로 제한.
          child: ContentWidth(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 화면 제목 — 목업의 "My Profile".
              Center(
                child: Text('My Profile',
                    style: AppTextStyles.pointBoldEn(
                        size: 24, color: AppColors.primaryDark)),
              ),
              const SizedBox(height: 28),
              _field('닉네임', _nickname),
              const SizedBox(height: 16),
              _field('나이', _age, isNumber: true),
              const SizedBox(height: 24),
              const Text('성별', style: AppTextStyles.title),
              const SizedBox(height: 12),
              // 성별 2칸 — 고양이 이미지로.
              Row(
                children: [
                  Expanded(
                      child: _genderBox(
                          'female', '여성', AppAssets.profileFemale)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _genderBox('male', '남성', AppAssets.profileMale)),
                ],
              ),
              // 임신·수유 — 여성 선택 시에만 묻는다.
              if (_gender == 'female') ...[
                const SizedBox(height: 24),
                const Text('임신 및 수유 여부', style: AppTextStyles.title),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _pregnancyChip('none', '해당없음')),
                    const SizedBox(width: 8),
                    Expanded(child: _pregnancyChip('pregnant', '임신 중')),
                    const SizedBox(width: 8),
                    Expanded(child: _pregnancyChip('nursing', '수유 중')),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              // 피부고민 — 성별 무관하게 항상. 다중 선택.
              const Text('피부고민', style: AppTextStyles.title),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in SkinConcern.values) _concernChip(c),
                ],
              ),
              const SizedBox(height: 32),
              if (widget.isEditing)
                // 수정 모드 — 저장하고 마이페이지로 돌아간다.
                Align(
                  alignment: Alignment.centerRight,
                  child: _navText('저장', onTap: _saveAndBack),
                )
              else ...[
                // NEXT → BSTI 검사.
                Align(
                  alignment: Alignment.centerRight,
                  child: _navText('BSTI TEST', onTap: _next),
                ),
                const SizedBox(height: 8),
                // HOME → 한 번 묻고 홈으로.
                Align(
                  alignment: Alignment.centerRight,
                  child: _navText('HOME', dim: true, onTap: _goHome),
                ),
              ],
            ],
          )),
        ),
      ),
    );
  }

  /// 라벨 + 픽셀 입력칸 (검색창과 같은 스타일).
  Widget _field(String label, TextEditingController c,
      {bool isNumber = false}) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: AppTextStyles.title)),
        const SizedBox(width: 12),
        Expanded(
          child: PixelBox(
            borderColor: AppColors.textPrimary,
            pixel: 6,
            borderWidth: 2.5,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: c,
              keyboardType: isNumber ? TextInputType.number : null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }

  /// 성별 선택 박스 — 고양이 이미지 + 라벨. 고르면 포인트 색 테두리.
  Widget _genderBox(String value, String label, String asset) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() {
        _gender = value;
        // 남성으로 바꾸면 임신·수유 선택은 의미가 없으니 지운다.
        if (value != 'female') _pregnancy = null;
      }),
      behavior: HitTestBehavior.opaque,
      child: PixelBox(
        borderColor: selected ? AppColors.primary : AppColors.outline,
        fillColor: selected ? AppColors.primaryLight : AppColors.surface,
        pixel: 6,
        borderWidth: selected ? 3 : 2,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(height: 90),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.title.copyWith(
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  /// 임신·수유 선택 칩.
  Widget _pregnancyChip(String value, String label) {
    final selected = _pregnancy == value;
    return GestureDetector(
      onTap: () => setState(() => _pregnancy = value),
      behavior: HitTestBehavior.opaque,
      child: PixelBox(
        borderColor: selected ? AppColors.primary : AppColors.outline,
        fillColor: selected ? AppColors.primaryLight : AppColors.surface,
        pixel: 4,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }

  /// 피부고민 칩 (다중 선택). 화면엔 한글 라벨만, 저장은 code 로.
  Widget _concernChip(SkinConcern c) {
    final selected = _concerns.contains(c);
    return GestureDetector(
      onTap: () => setState(() {
        selected ? _concerns.remove(c) : _concerns.add(c);
      }),
      behavior: HitTestBehavior.opaque,
      child: PixelBox(
        borderColor: selected ? AppColors.primary : AppColors.outline,
        fillColor: selected ? AppColors.primaryLight : AppColors.surface,
        pixel: 4,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(c.label,
            style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }

  /// 목업의 "NEXT →" / "HOME →" 텍스트 버튼.
  Widget _navText(String label, {required VoidCallback onTap, bool dim = false}) {
    final color = dim ? AppColors.textSecondary : AppColors.primaryDark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.pointBoldEn(size: 22, color: color)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: color, size: 22),
        ],
      ),
    );
  }

  /// 입력한 프로필을 저장한다. 추천·보고서가 이 값을 읽는다.
  ///
  /// 프로필 저장 — 로컬 상태를 먼저 갱신하고 서버에 올린다.
  /// 서버 실패는 [UserProfileNotifier.save] 가 로그로 삼킨다(게스트·오프라인).
  Future<void> _save() {
    return ref.read(userProfileProvider.notifier).save(
          UserProfile(
            nickname:
                _nickname.text.trim().isEmpty ? null : _nickname.text.trim(),
            age: int.tryParse(_age.text.trim()),
            gender: _gender,
            pregnancy: _pregnancy,
            concerns: {..._concerns},
            // bstiType 은 안 넘긴다 — notifier 가 현재 값을 지켜준다.
          ),
        );
  }

  /// 기다리지 않고 돌아가면 마이페이지가 옛 값을 보여준다.
  Future<void> _saveAndBack() async {
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('프로필을 저장했습니다.')));
    context.go('/profile');
  }

  /// BSTI 검사로. 목데이터 시연이라 입력을 강제하지 않는다.
  void _next() {
    // 저장을 기다리지 않고 넘어간다 — 서버 왕복 때문에 화면이 멈추지 않게.
    unawaited(_save());
    // 프로필을 마쳤으면 온보딩 완료 — 안 그러면 라우터가 /bsti 를 막고
    // 스플래시로 되돌린다. (redirect: !onboarded && 온보딩 밖 → /splash)
    ref.read(authControllerProvider.notifier).completeOnboarding();
    context.go('/bsti');
  }

  /// 홈으로 — 프로필을 안 쓰면 추천이 안 되므로 한 번 묻는다.
  Future<void> _goHome() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text(
          '프로필 정보를 기반으로,\n맞춤형 화장품 추천이 가능합니다.\n프로필 작성을 계속 진행할까요?',
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
            child: const Text('계속하기'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      // 홈으로 나가도 지금까지 고른 고민은 살려둔다 (추천이 읽는다).
      unawaited(_save());
      // 홈도 온보딩 밖이라 완료 처리해야 리다이렉트에 안 막힌다.
      ref.read(authControllerProvider.notifier).completeOnboarding();
      context.go('/home');
    }
  }
}
