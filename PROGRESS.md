# cosmos_client 진행 상황 (작업 이어가기용)

> 최종 업데이트: 2026-07-13 · 이 파일을 읽으면 지금까지 맥락을 잡고 바로 이어서 작업 가능.
> 담당: 금별(byeol-lab) · 프론트(디자인 파트)

---

## 0. 이 프로젝트가 뭔지

- **cosmos** = 화장품 성분 기반 추천 앱. 전성분 해설 · 제품 교차조회 · BSTI(피부 MBTI) 기반 성분 추천.
- 이 레포(`cosmos_client`) = **Flutter 프론트**. 백엔드는 별도 레포 `cosmos_server`(FastAPI).
- 앱은 화면·입력·로그인(Supabase Auth)·서버 호출만. 로직·데이터·LLM은 서버가 담당.
- 내 역할: **프론트 디자인 파트** + API 연결 지점만 열어두기.

## 1. 기술 스택 (확정)

Flutter(Dart 3.12/Flutter 3.44.5) · Riverpod · go_router · supabase_flutter + dio · Hive + flutter_secure_storage · Material 3.

## 2. 개발 환경 (중요)

- **Flutter는 `C:\src\flutter`에 설치됨.** PATH에 없어서 매번 `export PATH="/c/src/flutter/bin:$PATH"` 해줘야 함.
- 앱 실행: `flutter run -d chrome --web-port=8088` → **http://localhost:8088**
- **폰 화면처럼 보기**: 크롬에서 F12 → Ctrl+Shift+M → iPhone 기기 선택.
- 코드 고치면 매번 재시작(`taskkill //F //IM dart.exe` 후 재실행). 핫리로드는 백그라운드라 아직 안 씀.

## 3. Git 브랜치 상태

- `main` — 팀 공식. 이미 머지됨: 스캐폴드(PR#1) + 디자인 시스템 문서(PR#3).
- **현재 작업 브랜치: `feat/design-setup`** (아직 push 안 함). 여기서 디자인·화면 작업 중.
- 규칙: main 직접 커밋 금지 → 브랜치 → PR → 리뷰 → 머지. 커밋은 영어 Conventional Commits.

## 4. 디자인 시스템 (docs/design-system.md 참고 — 코드에 이미 반영)

**컬러** (`lib/app/theme/app_colors.dart`, 피그마 Color Chart 기준):
- primary #7490D2 (메인 블루) / primaryDark #112D55 (딥 네이비, 헤드라인·로고·갈무리 제목)
- primaryLight #C0D7F8 / accent #FCAB43 (오렌지 포인트) / background #FAFAFA
- textPrimary #3B3939 / textSecondary #8A8A8A / outline #CAC4D0

**폰트** (`assets/fonts/`, 파일 다운로드 완료):
- 본문 = **Pretendard** (Regular/Medium/Bold)
- 포인트(큰 제목) = **갈무리** (Galmuri9, Galmuri11, Galmuri11-Bold) — 픽셀 서체

**타이포** (`lib/app/theme/app_text_styles.dart`) — 화면에서 size 직접 넣지 말고 아래만 사용:
- 본문(Pretendard): headline 24 / title 18 / body 15 / caption 13 / button 16
- 포인트(갈무리) 3단계: **pointLg 44** / **pointMd 30** / **pointSm 17** (기본색 primaryDark)
- 큰 글자 제목은 전부 갈무리(point*)로 통일하는 방향.

## 5. 에셋 폴더 구조 (assets/README.md)

```
assets/
├─ fonts/           Pretendard·갈무리 (완료)
├─ icons/
│  ├─ social/       kakao.png·naver.png·google.png (정품 다운 완료) / apple 없음(아이콘 폴백)
│  ├─ nav/          (비어있음 — 햄버거·마이 아이콘 나중에)
│  └─ common/       (비어있음)
└─ images/
   ├─ logo/         logo_full.png(고양이+문구, 스플래시) · logo_wordmark.png(COSMOS, 앱바) ✅
   ├─ onboarding/   (비어있음 — 온보딩 일러스트 필요)
   ├─ bsti/         (비어있음)
   ├─ home/         (비어있음 — shelf_products/shelf_make/myitem_question.png 필요)
   └─ common/
```
- **로고 GIF 가능**: Image.asset이 GIF 재생함. logo_full.gif 주면 스플래시에서 움직이는 로고 됨.
- 화면 코드는 `AppAssets`(lib/app/theme/app_assets.dart) 경로 상수만 참조. 문자열 하드코딩 안 함.

## 6. 화면 흐름 (피그마 와이어프레임 기준 — 이미 구현된 라우팅)

```
스플래시(고양이 로고 + START 버튼) → 온보딩(4장 슬라이드 스와이프)
  → 로그인(온보딩 끝, 하단 시트 + 배경 어둡게)
     ├─ "로그인 없이 시작하기" → 팝업(비회원 안내)
     │     ├─ "홈으로" → 게스트로 홈
     │     └─ "계속하기" → 프로필 등록
     └─ 소셜 로그인(카카오·네이버·구글·애플) — 지금은 "준비 중" 스낵바
  → 프로필 등록 → 피부고민 선택 → 등록완료(BSTI 검사 vs 홈 선택)
  → 홈(허브)

홈 하단 탭: 홈 / 화장대 / 마이
홈 상단바: ☰ 햄버거(좌) · COSMOS 로고(중앙, 56px) · 👤 마이페이지(우)
```

**인증 상태** (`lib/features/auth/data/auth_state.dart`): `onboarded` 플래그로 온보딩 완료 여부 추적.
라우터가 `onboarded==false`면 진입플로우(스플래시/온보딩/로그인)로 가둠.

## 7. 화면별 구현 상태

| 화면 | 상태 |
| --- | --- |
| 스플래시 | ✅ 로고 + START 버튼 (화면폭 85% 로고) |
| 온보딩 인트로 | ✅ 4장 슬라이드(PageView) + 인디케이터. 제목 갈무리(pointMd). **일러스트 자리 비어있음(뱃지로 대체)** |
| 로그인 | ✅ 하단 시트 + 소셜 4버튼(정품 로고) + 게스트 팝업 |
| 프로필 등록 | 🔲 PlaceholderScreen (닉네임·나이·성별 입력 UI 필요) |
| 피부고민 선택 | 🔲 PlaceholderScreen (칩 다중선택 UI 필요) |
| 온보딩 완료 | ✅ BSTI vs 홈 선택 (PlaceholderScreen 기반) |
| 홈 | ✅ 피그마 가안 레이아웃(상단바·검색바·3섹션). **일러스트 3개 자리 비어있음(플레이스홀더)** |
| BSTI 검사/결과 | 🔲 PlaceholderScreen (결과 모델 BstiResult는 있음) |
| 나의 화장대 | 🔲 PlaceholderScreen |
| 맞춤 추천 | 🔲 PlaceholderScreen |
| 마이페이지 | 🔲 기존 profile_screen (로그아웃 등) |

## 8. 컴포넌트

- **PixelButton** (`lib/core/widgets/pixel_button.dart`): 픽셀 스타일 버튼(각진 테두리+그림자, primary→primaryLight 눌림). 갈무리 라벨. **피드백: 그림자 어둡고 비트맵 느낌 약함 → 개선 필요.** 아직 화면에 미적용(홈은 카드/텍스트로).
- PlaceholderScreen (`lib/core/widgets/`): 미구현 화면용 임시 뼈대.

## 9. 백엔드 연동 (docs/api-requirements.md 참고)

- 서버 5모듈: ingredient_search / ingredient_detail / product_compare / bsti / recommendation. 현재 대부분 501 스텁.
- 프론트가 요청한 **신규 테이블 3개** (사용자 소유, user_id 소유권 검사 필수):
  - `user_profiles` (nickname, age, gender, skin_concerns[])
  - `user_shelf` (item_type, ref_id — 제품/성분 참조)
  - `bsti_results` (type_code, axes json, recommended/caution ingredients json)
- 데이터 규칙: 결측 null / safety_note null → "안전성 확인 불가" / 안전 단정 금지.

## 10. Supabase MCP (연결 완료, 서버 정상 확인됨)

- **Supabase MCP 추가 완료** (`claude mcp add supabase`). `claude mcp get supabase` → ✓ Connected (v0.8.2). 서버·토큰 정상 검증됨.
- ⚠️ **MCP 도구는 세션 시작 시에만 로드됨.** 도구가 안 붙어 있으면 Claude Code 재시작(`/exit` 후 `claude` 재실행).
- ⚠️ **보안**: Personal Access Token(`sbp_...`)이 `.claude.json`에 평문으로 남음. **작업 끝나면 revoke 후 재발급** (재발급하면 MCP 재등록 필요).
- 참고: 신규 테이블 3개(9번) 생성은 **나중 작업** — 지금은 안 함. DB는 원래 백엔드 담당이라 팀 협의 필요.

## 11. 지금 열려있는 피드백/다음 할 일

- [ ] 온보딩 슬라이드 제목이 갈무리라 길면 줄바꿈될 수 있음 → 실제 보고 크기 조정
- [ ] PixelButton 비트맵 느낌 강화 + 그림자 밝게 (사용자 피드백)
- [ ] 일러스트 PNG 채우기: 온보딩 4장, 홈 3개 (사용자 제공 예정)
- [ ] 픽셀 아이콘(햄버거·마이·검색 등) 교체 (사용자 제공 예정)
- [ ] 애플·네이버 소셜 심볼 정리
- [ ] 프로필/피부고민/BSTI/화장대/추천 화면 실제 UI 구현 (지금 placeholder)
- [ ] **Supabase 테이블 생성** (재시작 후 MCP로)

## 12. 자주 쓰는 명령

```bash
# Flutter PATH + 실행
export PATH="/c/src/flutter/bin:$PATH"
cd /c/Users/golds/cosmos_app
flutter run -d chrome --web-port=8088

# 정적 분석
flutter analyze

# 앱 재시작 (코드 변경 반영)
taskkill //F //IM dart.exe; flutter run -d chrome --web-port=8088
```
