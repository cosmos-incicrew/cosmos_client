import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 로컬 저장소 초기화 및 접근 헬퍼.
///
/// - Hive: 일반 캐시 (최근 검색어, 조회한 제품 등 비민감 데이터)
/// - flutter_secure_storage: 토큰 등 민감 데이터
class LocalStorage {
  const LocalStorage._();

  static const String recentSearchBox = 'recent_search';
  static const String prefsBox = 'prefs';

  static const _secure = FlutterSecureStorage();

  /// 앱 시작 시 한 번 호출.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(recentSearchBox);
    await Hive.openBox(prefsBox);
  }

  static Box<String> get recentSearches =>
      Hive.box<String>(recentSearchBox);

  static Box get prefs => Hive.box(prefsBox);

  // ---- 민감 데이터 (secure storage) ----
  static Future<void> writeSecure(String key, String value) =>
      _secure.write(key: key, value: value);

  static Future<String?> readSecure(String key) => _secure.read(key: key);

  static Future<void> deleteSecure(String key) => _secure.delete(key: key);
}
