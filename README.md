# cosmos 디자인 시스템 (프론트)

> 작성: 금별 · 2026-07-10 · 대상: cosmos 프론트 팀
> 근거: 피그마 "Color Chart"(Page 2, node 87:2027)에서 추출한 실제 색값 + 폰트 지정.
> 코드 반영 위치: 색상 `lib/app/theme/app_colors.dart`, 타이포 `lib/app/theme/app_text_styles.dart`, 테마 `lib/app/theme/app_theme.dart`.
> 원칙: 화면에서 색·크기를 하드코딩하지 않고 아래 토큰(AppColors / AppTextStyles)만 참조한다.

---

## 1. 컬러 팔레트

피그마 Color Chart 견본에서 픽셀값을 추출한 확정 컬러다. 디자인 변경 시 아래 hex만 교체하면 전체 톤이 따라온다.

| 토큰 | Hex | 용도 |
| --- | --- | --- |
| primary | #7490D2 | 메인 블루. 버튼·강조·시드 컬러 |
| primaryLight | #C0D7F8 | 연블루. 배경·칩·비활성 |
| accent | #FCAB43 | 오렌지 포인트. 강조·CTA·주요 액션 |
| background | #FAFAFA | 화면 배경 |
| surface | #FFFFFF | 카드·시트 표면 |
| textPrimary | #3B3939 | 기본 텍스트 (차콜) |
| textSecondary | #8A8A8A | 보조 텍스트 (견본 #CAC4D0은 대비가 약해 가독성용으로 조정) |
| outline | #CAC4D0 | 보더·구분선 (라벤더 그레이) |

**시맨틱 컬러** (성분 안전도 배지 등):

| 토큰 | Hex | 용도 |
| --- | --- | --- |
| safe | #4CAF7D | 안전·권장 성분 |
| caution | #FCAB43 | 주의 (포인트 오렌지와 통일) |
| danger | #E07A5F | 위험·주의 성분 |

> Material 3 `ColorScheme.fromSeed(seedColor: primary)`로 파생색을 자동 생성한다.
> 시맨틱 컬러(safe/caution/danger)는 팔레트에 명시가 없어 임시값 — 디자인 확정 시 교체 가능.

---

## 2. 폰트

| 용도 | 폰트 | 코드에서 부르는 이름 |
| --- | --- | --- |
| 본문·UI (기본) | Pretendard | Pretendard |
| 포인트 (제목·강조) | 갈무리 9 | Galmuri9 |
| 포인트 (큰 타이틀) | 갈무리 11 | Galmuri11 |

- 본문은 무난한 한글 산세리프 **Pretendard**를 앱 전역 기본으로 깐다 (`app_theme.dart`의 `fontFamily`).
- 제목·타입코드 같은 강조에만 픽셀 폰트 **갈무리**를 쓴다.
- 둘 다 OFL 라이선스라 앱 임베딩·상업 이용 가능.
- 폰트 파일을 `assets/fonts/`에 넣고 pubspec 경로만 맞추면 적용된다. 자세한 건 [assets/fonts/README.md](assets/fonts/README.md).

---

## 3. 타이포그래피 (크기·굵기)

`AppTextStyles`에 정의됨. 화면에서 fontSize를 직접 쓰지 않고 아래 스타일을 참조한다.

**본문 (Pretendard):**

| 이름 | 크기 | 굵기 | 용도 |
| --- | --- | --- | --- |
| headline | 24 | Bold(700) | 화면 상단 큰 제목 |
| title | 18 | Bold(700) | 섹션 제목 |
| body | 15 | Regular(400) | 본문 |
| caption | 13 | Regular(400) | 설명·캡션 (보조색) |
| button | 16 | SemiBold(600) | 버튼 라벨 |

**포인트 (갈무리):**

| 이름 | 기본 크기 | 용도 |
| --- | --- | --- |
| point9 (갈무리9) | 14 | 작은 포인트 라벨·태그·소제목 강조 |
| point11 (갈무리11) | 28, Bold | 큰 포인트 타이틀 (BSTI 타입코드 등) |

> 줄간격: 제목 1.3, 본문 1.5.

---

## 4. 컴포넌트 스타일 (테마에 통일)

`app_theme.dart`에서 통일한다. 화면에서 개별 스타일을 새로 만들지 않는다.

| 컴포넌트 | 규칙 |
| --- | --- |
| 버튼(Filled/Outlined) | 높이 52, 라운드 14, Bold 라벨 |
| 카드 | 라운드 16, elevation 0, 얇은 아웃라인 |
| 입력창 | filled, 라운드 14, 포커스 시 primary 보더 |
| 칩 | 라운드 20 (피부고민·성분 태그) |
| 앱바 | centerTitle, elevation 0, 스크롤 시 살짝 그림자 |

**공통 위젯** (`lib/core/widgets`): 로딩(LoadingView)·에러(ErrorView)·빈 상태(EmptyView)·플레이스홀더(PlaceholderScreen)는 만들어 둔 걸 재사용한다.

---

## 5. 라이트/다크

- `ColorScheme.fromSeed`로 라이트·다크 모두 생성. `themeMode: system`.
- 토큰 기반이라 다크가 자동으로 따라오지만, 디자인 확정 후 대비를 한 번 점검한다.

---

## 6. 아이콘·이미지

- 아이콘은 Material Symbols 기본 사용 (피그마도 `material-symbols:*` 사용).
- 성분·제품 썸네일은 `cached_network_image`로 로드, 없으면 플레이스홀더 박스.
- 앱 로고·일러스트는 `assets/images/`에 두고 디자인 확정 시 교체.

---

## 7. 확정 대기 항목

- [ ] 시맨틱 컬러(safe/caution/danger) 디자인 값 (현재 임시값)
- [ ] 귀여운 폰트 파일 배치 + 라이선스 파일
- [ ] 앱 로고·일러스트 에셋
- [ ] 다크 모드 대비 점검
