# 개발 규칙

> 작성일: 2026-07-09 · 작성: 금별
>
> 대상: cosmos_client에 코드를 쓰는 모든 팀원. PR 전에 이 문서 기준으로 셀프 리뷰한다.
>
> 서버 규칙은 [cosmos_server/docs/conventions.md](https://github.com/cosmos-incicrew/cosmos_server/blob/main/docs/conventions.md).
> API 계약·인증은 [architecture.md](architecture.md)를 따른다.

## 코드 스타일

- **포맷·린트:** `dart format .`·`flutter analyze`를 통과해야 머지할 수 있다.
  설정은 `analysis_options.yaml`(flutter_lints) 기준. 개인 포매터 설정을 쓰지 않는다.
- **네이밍:** 변수·함수·매개변수 `lowerCamelCase` / 클래스·enum·typedef `UpperCamelCase` /
  상수 `lowerCamelCase`(Dart 관례, `SCREAMING_CAPS` 아님) / 파일명 `snake_case.dart`.
- **매직 넘버·문자열 금지** — 의미 있는 이름의 상수로 추출한다. 색상은 `AppColors`,
  API 주소·키는 `Env`로. 화면에 하드코딩하지 않는다.
- **타입:** `var`·`dynamic` 남용 금지. public API(생성자·반환값)에는 타입을 명시한다.
  `const`를 쓸 수 있는 위젯·값은 반드시 `const`로(리빌드 비용 절감).
- **주석:** 코드가 말 못하는 "왜"만 쓴다. 무엇을 하는지 설명하는 주석은 쓰지 않는다.
  (서버 규칙과 동일)

## 폴더·모듈 구조

- 기능은 `lib/features/<기능>/` 아래 `data/`(모델·repository)와 `presentation/`
  (screens·widgets·providers)로 나눈다. 의존 방향은 `presentation → data` 한 방향.
  화면에서 서버 호출·저장소 접근을 직접 하지 않고 repository를 거친다.
- **기능 간 직접 import 금지.** 공유가 필요하면 `lib/core/`(클라이언트·설정·공통 위젯)로
  올린 뒤 양쪽에서 쓴다. (서버의 import-linter 규칙과 같은 취지 — 프론트는 리뷰로 강제)
- 외부 접근(Supabase·서버 REST)은 반드시 `core/network`의 클라이언트를 거친다.
  화면이나 repository에서 `Dio()`·`Supabase.instance`를 새로 만들지 않는다.

## 상태 관리 (Riverpod)

- 전역·화면 상태는 **Riverpod**로 관리한다. `setState`는 순수 로컬 UI 상태
  (텍스트필드 포커스 등)에만 쓴다.
- Provider는 해당 기능의 `presentation/providers/`에 둔다. 공유 provider만 `core`로 올린다.
- 비동기 데이터는 `AsyncValue`(FutureProvider/AsyncNotifier)로 다뤄 로딩·에러·데이터
  상태를 화면에서 `when`으로 분기한다. 로딩·에러는 `core/widgets`의 공통 뷰를 쓴다.

## 라우팅 (go_router)

- 라우트는 `lib/app/router/`에서 중앙 관리한다. 화면에서 경로 문자열을 임의로 만들지 않는다.
- 인증 상태에 따른 리다이렉트는 라우터 `redirect`에서 처리한다(화면에서 분기하지 않는다).
- 하단 탭은 `StatefulShellRoute`로, 상세·검색 등 전체 화면은 쉘 밖으로 push한다.

## 서버 연동

- API 계약(경로·에러 포맷·인증)은 [architecture.md](architecture.md) §6을 따른다.
- 서버 호출은 `dioProvider`를 통해서만 한다. 세션 JWT 주입·공통 에러 파싱은 인터셉터가 담당한다.
- 응답 모델의 `fromJson`은 **API 명세서(Notion) 확정 후** 실제 필드에 맞춘다. 지금은 목업 기준.
- 서버가 501을 주면 "준비 중"으로 처리한다(에러로 취급하지 않는다).

## 민감 정보

- **`.env`·API 키·시크릿·Supabase 키를 코드나 저장소에 커밋 금지.** 값은 `--dart-define`으로
  주입하고, `Env`는 기본값을 비워 둔다. 토큰 등 민감 데이터는 `flutter_secure_storage`에만 둔다.
- 실수로 키가 스테이징되면 커밋을 멈추고 팀에 알린다. (서버 규칙과 동일)

## 테스트

- 실행: `flutter test`. `test/`는 `lib/` 구조를 미러링한다.
- 위젯 테스트는 화면 렌더·주요 상호작용을 검증한다. repository는 목업으로 주입해 네트워크를 타지 않는다.
- **외부 서비스(Supabase·서버)는 호출하지 않는다.** provider override로 목업 repository를 주입한다.

## Git

- `main` 직접 커밋 금지. 항상 브랜치 → PR → 리뷰 → 머지. 브랜치명은 영어:
  `feat/<기능>-<설명>`, 버그 `fix/...`, 문서 `docs/...`, 잡무 `chore/...`.
  (서버 팀 규칙과 동일)
- 커밋은 Conventional Commits(영어): `feat:` `fix:` `refactor:` `docs:` `test:` `chore:`.
  하나의 커밋은 하나의 논리적 변경만.
- **다른 사람 담당 기능을 상의 없이 수정하지 않는다.**
- PR: ① diff를 처음부터 끝까지 셀프 리뷰 → ② `flutter analyze`·`dart format`·`flutter test`
  통과 확인 → ③ 담당 기능 리뷰어 지정.
