# assets — 디자인 에셋

앱의 디자인 요소(폰트·아이콘·이미지)를 종류별로 분리해 둔다.
**코드(`lib/`)와 완전히 분리**되며, 에셋 안에서도 용도별로 섞이지 않게 폴더를 나눈다.

```
assets/
├─ fonts/           폰트 (Pretendard 본문, 갈무리 포인트)
├─ icons/           아이콘 (PNG). 작은 UI 심볼
│  ├─ social/       소셜 로그인 (kakao, naver, google)
│  ├─ nav/          하단 탭·네비게이션 아이콘
│  └─ common/       검색·화살표 등 공통 아이콘
└─ images/          이미지 (PNG). 로고·일러스트·사진
   ├─ logo/         앱 로고, BSTI 브랜드 이미지
   ├─ onboarding/   온보딩 일러스트
   ├─ bsti/         BSTI 타입별 캐릭터·결과 이미지
   └─ common/       공통 배경·플레이스홀더
```

## 파일 넣는 규칙

- **PNG 위주.** 고해상도 대응이 필요하면 `이름@2x.png`, `이름@3x.png`도 같이 넣는다
  (Flutter가 화면 배율에 맞춰 자동 선택).
- 파일명은 `snake_case`(예: `kakao_logo.png`, `bsti_ospw.png`).
- 새 파일을 넣으면 `pubspec.yaml`의 `assets:` 목록에 폴더가 등록돼 있는지 확인
  (폴더 단위로 등록돼 있어 같은 폴더면 추가 등록 불필요).

## 원칙

- 화면 코드에서 경로 문자열을 직접 쓰지 않고, `lib/app/theme` 또는 상수로 경로를 모아 참조하는 걸 권장.
- 라이선스가 있는 에셋(폰트 등)은 LICENSE 파일을 함께 둔다.
