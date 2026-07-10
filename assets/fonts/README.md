# 폰트 넣는 법

이 앱은 폰트를 2종 쓴다.

| 용도 | 패밀리 이름(코드에서 부르는 이름) | 폰트 | 파일 위치 |
| --- | --- | --- | --- |
| 본문(기본) | `Pretendard` | Pretendard (무난한 한글 산세리프) | `assets/fonts/Pretendard-*.ttf` |
| 포인트(제목·강조) | `Galmuri9` / `Galmuri11` | 갈무리 9, 갈무리 11 (픽셀 폰트) | `assets/fonts/Galmuri9.ttf`, `assets/fonts/Galmuri11.ttf` |

## 1. 폰트 파일을 이 폴더에 복사
- **본문:** Pretendard `Regular`·`Bold` (또는 Medium/SemiBold) → `assets/fonts/`
  - 다운: https://github.com/orioncactus/pretendard (SIL OFL, 임베딩 허용)
- **포인트:** 갈무리 9·11 → `assets/fonts/`
  - 다운: https://galmuri.quiple.dev (OFL, 임베딩 허용)

## 2. pubspec.yaml — 이미 등록돼 있음
`pubspec.yaml`의 `fonts:` 섹션에 위 3개 패밀리가 등록돼 있다. **파일명만 실제와 맞추면** 된다.
(파일명이 다르면 pubspec의 `asset:` 경로를 실제 파일명으로 수정)

## 3. 코드에서 쓰는 법 — 이미 배선됨
- 앱 기본 폰트 = `Pretendard` (`app_theme.dart`의 `fontFamily`).
- 포인트가 필요한 곳(제목·타입코드 등)만 `AppTextStyles.point9` / `AppTextStyles.point11`을 쓴다.
  (`lib/app/theme/app_text_styles.dart`)

## 라이선스
- Pretendard·갈무리 모두 **OFL(임베딩·상업 이용 허용)**. LICENSE 파일을 폰트와 함께 이 폴더에 같이 두면 좋다.
