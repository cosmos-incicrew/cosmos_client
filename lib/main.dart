import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/supabase_client.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 로컬 저장소 (Hive) 초기화
  await LocalStorage.init();

  // Supabase 초기화 (Env 미설정 시 자동 스킵)
  await SupabaseService.init();

  // TODO: 카카오 SDK 초기화
  // KakaoSdk.init(nativeAppKey: '...');

  runApp(
    const ProviderScope(
      child: CosmosApp(),
    ),
  );
}
