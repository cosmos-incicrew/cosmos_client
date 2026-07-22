// 서버 프로필 API 매핑 검증.
//
// 임신·수유는 화면의 3지 선택(none/pregnant/nursing)과 서버의 bool 두 개를
// 오가는데, "안 물어본 상태(null)"와 "해당없음(false)"이 섞이면 금기 성분 경고가
// 조용히 사라진다. 그 경계를 못 박는다.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:typed_data';

import 'package:cosmos_app/features/onboarding/data/profile_repository.dart';
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:cosmos_app/features/onboarding/data/skin_concern.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 요청을 실제로 보내지 않고 마지막 payload 만 붙잡아 두는 대역.
class _CapturingAdapter implements HttpClientAdapter {
  Map<String, dynamic>? lastBody;
  int status = 200;
  Map<String, dynamic> responseBody = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = options.data;
    if (data is Map<String, dynamic>) lastBody = data;
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _CapturingAdapter adapter;
  late ProfileRepository repository;

  setUp(() {
    adapter = _CapturingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    repository = ProfileRepository(dio);
  });

  test('임신 선택은 is_pregnant 로만 참이 된다', () async {
    await repository.save(const UserProfile(pregnancy: kPregnancyPregnant));

    expect(adapter.lastBody?['is_pregnant'], isTrue);
    expect(adapter.lastBody?['is_nursing'], isFalse);
  });

  test('수유 선택은 is_nursing 으로만 참이 된다', () async {
    await repository.save(const UserProfile(pregnancy: kPregnancyNursing));

    expect(adapter.lastBody?['is_pregnant'], isFalse);
    expect(adapter.lastBody?['is_nursing'], isTrue);
  });

  test('안 물어봤으면 false 가 아니라 null 로 보낸다', () async {
    // 남성 선택 등으로 화면이 아예 묻지 않은 경우. false 로 보내면 서버가
    // "확인함, 해당없음"으로 알아듣고 경고를 붙이지 않는다.
    await repository.save(const UserProfile());

    expect(adapter.lastBody?['is_pregnant'], isNull);
    expect(adapter.lastBody?['is_nursing'], isNull);
  });

  test('피부고민은 코드 배열로 나간다', () async {
    await repository.save(
      const UserProfile(concerns: {SkinConcern.acne, SkinConcern.pores}),
    );

    expect(adapter.lastBody?['skin_concerns'], containsAll(['acne', 'pores']));
  });

  test('서버 응답을 프로필로 되돌린다', () async {
    adapter.responseBody = {
      'user_id': 'uuid',
      'nickname': '민경',
      'age': 28,
      'gender': 'female',
      'skin_concerns': ['acne'],
      'is_pregnant': false,
      'is_nursing': true,
      'created_at': null,
      'updated_at': null,
    };

    final profile = await repository.fetch();

    expect(profile?.nickname, '민경');
    expect(profile?.age, 28);
    expect(profile?.pregnancy, kPregnancyNursing);
    expect(profile?.concerns, {SkinConcern.acne});
  });

  test('온보딩 전(404)은 실패가 아니라 null 이다', () async {
    adapter.status = 404;
    adapter.responseBody = {
      'error': {'code': 'PROFILE_NOT_FOUND', 'message': '프로필이 아직 없습니다.'},
    };

    expect(await repository.fetch(), isNull);
  });
}
