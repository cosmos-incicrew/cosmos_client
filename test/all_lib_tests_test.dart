// lib/ 안에 있는 테스트를 모아서 실행하는 진입점.
//
// 왜 필요한가:
//   일부 테스트는 소스 바로 옆(lib/features/...)에 있다. 그런데 인자 없는
//   `flutter test`는 test/ 폴더만 자동 실행하므로, 이 파일이 없으면 그 테스트들이
//   조용히 빠진다. 여기서 전부 불러와 함께 돌게 한다.
//
// 테스트를 lib/ 안에 새로 추가하면 이 파일에도 반드시 등록할 것.
// (등록을 잊으면 `flutter test`에서 누락된다)
import 'package:cosmos_app/features/bsti/bsti_data_test.dart' as bsti_data;
import 'package:cosmos_app/features/bsti/bsti_match_test.dart' as bsti_match;
import 'package:cosmos_app/features/bsti/bsti_result_store_test.dart'
    as bsti_store;
import 'package:cosmos_app/features/bsti/bsti_result_test.dart' as bsti_result;
import 'package:cosmos_app/features/bsti/bsti_test_screen_test.dart'
    as bsti_screen;
import 'package:cosmos_app/app/router/app_shell_test.dart' as app_shell;
import 'package:cosmos_app/features/auth/data/auth_mock_login_test.dart'
    as auth_mock;
import 'package:cosmos_app/features/home/presentation/screens/home_overflow_test.dart'
    as home_overflow;
import 'package:cosmos_app/features/my_shelf/data/shelf_preference_test.dart'
    as shelf_pref;
import 'package:cosmos_app/features/onboarding/presentation/screens/profile_setup_test.dart'
    as profile_setup;
import 'package:cosmos_app/features/report/data/report_engine_test.dart'
    as report_engine;
import 'package:cosmos_app/features/report/demo_cycle_test.dart' as demo_cycle;
import 'package:cosmos_app/features/report/presentation/screens/report_screen_test.dart'
    as report_screen;
import 'package:cosmos_app/features/my_shelf/presentation/screens/shelf_search_test.dart'
    as shelf_search;
import 'package:cosmos_app/features/my_shelf/presentation/widgets/preference_dialog_test.dart'
    as pref_dialog;

void main() {
  // BSTI
  bsti_data.main(); // 데이터 무결성 (개수·참조·채점 규칙)
  bsti_match.main(); // 성분 → 유형 매칭
  bsti_result.main(); // 결과 모델 파싱
  bsti_screen.main(); // 설문 화면 플로우
  bsti_store.main(); // 검사 결과 저장 (보고서가 읽음)

  // 보고서
  report_engine.main(); // 적합도 점수 계산
  report_screen.main(); // 보고서 화면
  demo_cycle.main(); // 로그인 → BSTI → 화장대 → 보고서 통합

  // 화장대 (검색 · 선호/기피)
  shelf_search.main(); // 제품·성분 검색 → 상세 이동
  shelf_pref.main(); // 선호/기피 저장소
  pref_dialog.main(); // 선호/기피 팝업 (제품/성분별 3버튼)

  // 홈
  home_overflow.main(); // 폰 크기에서 오버플로우 없이 렌더되는지

  // 인증
  auth_mock.main(); // 카카오 목 로그인 (SDK 연동 시 교체)

  // 네비게이션
  app_shell.main(); // 하단 탭 순서 = 라우터 브랜치 순서

  // 온보딩
  profile_setup.main(); // 프로필 등록 (성별·임신수유·피부고민)
}
