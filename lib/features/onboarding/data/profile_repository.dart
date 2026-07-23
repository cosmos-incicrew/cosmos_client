import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'profile_store.dart';
import 'skin_concern.dart';

/// 서버의 온보딩 프로필 API (cosmos_server `users` 모듈).
///
/// 경로·필드는 API 명세서 B-2 기준. 게스트는 토큰이 없어 401 이 나므로
/// 호출부가 실패를 감수하고 로컬 상태만 유지한다.
class ProfileRepository {
  const ProfileRepository(this._dio);

  static const String _path = '/api/v1/users/me/profile';
  static const String _accountPath = '/api/v1/users/me';

  final Dio _dio;

  /// 내 프로필 조회. **온보딩 전이면 null** (서버가 404 PROFILE_NOT_FOUND).
  Future<UserProfile?> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_path);
      final data = response.data;
      return data == null ? null : _fromJson(data);
    } on DioException catch (error) {
      // 404 는 "아직 없음"이라는 정상 응답이다 — 실패로 올리지 않는다.
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// 프로필 저장. 이미 있으면 서버가 통째로 덮어쓴다(수정 겸용).
  Future<void> save(UserProfile profile) async {
    await _dio.post<Map<String, dynamic>>(_path, data: _toJson(profile));
  }

  /// 회원 탈퇴 (되돌릴 수 없다).
  /// 지울 대상은 서버가 토큰에서 정한다 — user_id 를 보내지 않는다.
  Future<void> deleteAccount() async {
    await _dio.delete<void>(_accountPath);
  }

  static UserProfile _fromJson(Map<String, dynamic> json) {
    final concerns = (json['skin_concerns'] as List<dynamic>? ?? [])
        .map((code) => SkinConcern.fromCode(code as String))
        .nonNulls
        .toSet();
    return UserProfile(
      nickname: json['nickname'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      pregnancy: _pregnancyFrom(
        isPregnant: json['is_pregnant'] as bool?,
        isNursing: json['is_nursing'] as bool?,
      ),
      concerns: concerns,
      bstiType: json['bsti_type'] as String?,
    );
  }

  static Map<String, dynamic> _toJson(UserProfile profile) {
    final pregnancy = profile.pregnancy;
    return {
      'nickname': profile.nickname,
      'age': profile.age,
      'gender': profile.gender,
      'skin_concerns': [for (final c in profile.concerns) c.code],
      // 안 물어봤으면(남성 선택 등) null 로 보낸다 — 서버는 null 을 "미수집"으로
      // 보고 금기 성분을 제거하는 대신 경고만 붙인다.
      'is_pregnant': pregnancy == null ? null : pregnancy == kPregnancyPregnant,
      'is_nursing': pregnancy == null ? null : pregnancy == kPregnancyNursing,
      // 서버는 null 이면 기존 값을 덮지 않는다 (users/repository.py upsert_profile).
      'bsti_type': profile.bstiType,
    };
  }

  static String? _pregnancyFrom({bool? isPregnant, bool? isNursing}) {
    if (isPregnant == null && isNursing == null) return null;
    if (isPregnant ?? false) return kPregnancyPregnant;
    if (isNursing ?? false) return kPregnancyNursing;
    return kPregnancyNone;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});
