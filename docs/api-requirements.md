# 프론트 → 백엔드 API·데이터 명세

> 작성: 금별 · 2026-07-10
> 대상: cosmos 백엔드 팀
> 목적: 피그마 화면을 구현하려면 프론트가 서버에 무엇을 요청하고 어떤 형태로 받아야 하는지를 화면 단위로 정리한다.
> 진실 공급원: 확정 계약은 API 명세서(Notion). 이 문서는 프론트 관점의 정리이며, 값·필드는 백엔드와 협의해 확정한다.
> 스키마 근거: RAG 데이터 설계 / 경로·에러 규칙: cosmos_server conventions.md

---

## 0. 공통

| 항목 | 규칙 |
| --- | --- |
| 베이스 | `/api/v1` 아래, 리소스 복수형 |
| 인증 | 보호 API는 `Authorization: Bearer <Supabase JWT>`. 미인증 → 401 |
| 결측 | 값을 지어내지 말고 `null`. 빈 문자열 금지 |
| 안전성 | `safety_note`가 `null`이면 "확인 불가". "안전" 단정 금지 |
| 에러 | `{"error": {"code": "...", "message": "..."}}`. `code`로 분기, `message`(한국어) 노출 |
| 미구현 | 501 → 프론트 "준비 중" 처리 |
| 조인 키 | `ingredient_id`(INT)가 성분 조인 기준 키 |

---

## 1. 온보딩 · 프로필

### 1-1. 로그인
로그인은 Supabase Auth(`signInWithOAuth`)가 처리 → 서버 엔드포인트 없음.

| 필요 | 내용 |
| --- | --- |
| 공유 필요 | Supabase `URL`·`anon key`, 구글·카카오 OAuth Provider 설정, 리다이렉트 URL |

### 1-2. 프로필

| 기능 | 메서드·경로(제안) | 요청 | 응답 |
| --- | --- | --- | --- |
| 저장 | `POST /api/v1/users/me/profile` | `{nickname, age, gender, skin_concerns:[]}` | 저장된 프로필 |
| 조회 | `GET /api/v1/users/me/profile` | — | 동일 구조 |

```json
{ "nickname": "금별", "age": 29, "gender": "female", "skin_concerns": ["ACNE", "PORE"] }
```

| 확인 필요 | 내용 |
| --- | --- |
| gender 값 | `female / male / other` 로 고정? |
| skin_concerns | **피부고민 표준 코드 목록** (화면 칩 ↔ 서버 값 일치) |
| 저장 위치 | 서버 테이블 vs Supabase 메타데이터 (소유권 검사 주체) |

---

## 2. BSTI 검사

### 2-1. 문항

| 기능 | 메서드·경로(제안) | 응답 |
| --- | --- | --- |
| 문항 조회 | `GET /api/v1/bsti/questions` | 25문항 + 선택지 |

```json
{ "questions": [ { "id": 1, "text": "...", "options": [ {"label":"그렇다","value":"O_2"} ] } ] }
```

| 확인 필요 | 내용 |
| --- | --- |
| 문항 소스 | 서버 제공 vs 앱 내장 |

### 2-2. 결과

| 기능 | 메서드·경로(제안) | 요청 | 응답 |
| --- | --- | --- | --- |
| 제출·채점 | `POST /api/v1/bsti/results` | `{answers:[{question_id, value}]}` | 결과 객체 |
| 지난 결과 | `GET /api/v1/bsti/results/me` | — | 최근 결과 |

```json
{
  "type_code": "OSPW",
  "type_name": "진정이 먼저인 풀코스 케어 수련생",
  "axes": [ {"left_code":"O","left_label":"지성","left_percent":75,"right_code":"D","right_label":"건성"} ],
  "recommended_ingredients": [ {"ingredient_id":1024, "name_kor":"나이아신아마이드"} ],
  "caution_ingredients": [ {"ingredient_id":88, "name_kor":"알코올"} ]
}
```

| 확인 필요 | 내용 |
| --- | --- |
| 채점 주체 | 서버 담당 (문항→축→타입) |
| 축 | 4개 고정(O/D·S/R·P/N·W/T)? |
| 성분 id | 권장/주의 성분에 `ingredient_id` 포함? (상세 연결용) |
| 타입 텍스트 | 별명·설명 소스 (서버 vs 앱 내장) |

---

## 3. 나의 화장대

### 3-1. 통합 검색 (자동완성)

| 기능 | 메서드·경로(제안) | 파라미터 | 응답 |
| --- | --- | --- | --- |
| 검색 | `GET /api/v1/ingredients/search` | `q`, `type`(ingredient/product/all), `limit` | 성분·제품 혼합 |

```json
{
  "ingredients": [ {"ingredient_id":1024, "name_kor":"세라마이드", "name_eng":"CERAMIDE"} ],
  "products": [ {"product_id":77, "product_name":"아토베리어365 크림", "brand":"에스트라",
                 "main_category":"스킨케어", "sub_category":"크림", "image_url":null} ]
}
```

| 확인 필요 | 내용 |
| --- | --- |
| 응답 형태 | 성분·제품 통합 응답 vs 분리 호출 (피그마는 한 검색창 → 통합 선호) |
| 페이징 | 타이핑마다 호출(debounce) 전제, `limit` 기본값 |

### 3-2. 화장대 CRUD (사용자 소유)

| 기능 | 메서드·경로(제안) | 비고 |
| --- | --- | --- |
| 목록 | `GET /api/v1/users/me/shelf` | user_id 필터 필수 |
| 추가 | `POST /api/v1/users/me/shelf` | `{item_type, ref_id}` (product/ingredient) |
| 삭제 | `DELETE /api/v1/users/me/shelf/{id}` | 본인 항목만 |

| 확인 필요 | 내용 |
| --- | --- |
| 보안 | 모든 쿼리 user_id 필터 (RLS 우회 주의) |
| 화장대 점수 | "몇 점?" 계산 주체·기준 (서버 계산이면 score+근거 응답) |

### 3-3. 성분 상세

| 기능 | 메서드·경로(제안) | 응답 |
| --- | --- | --- |
| 성분 조회 | `GET /api/v1/ingredients/{ingredient_id}` | RAG 조합 형태(아래) |

```json
{
  "ingredient_id": 1024, "name_kor": "1,2-헥산다이올", "name_eng": "1,2-HEXANEDIOL",
  "efficacy": "보습 및 방부 보조 ...", "product_property": null,
  "recommended_skin_type": "지성·복합성", "source_ref": "1,2-Hexanediol-0001, COOS, PubChem",
  "restrictions": { "safety_note": null, "blend_regulation": "일본: 7.0%",
                    "limit_cond": "고농도 사용 시 자극 가능", "provis_atrcl": null, "is_registered_korea": true },
  "synonyms": ["헥산디올", "1,2-hexanediol"]
}
```
→ 이 구조 하나로 해설·주의사항·출처 표시 (프론트 `Ingredient` 모델과 1:1).

---

## 4. 맞춤 추천

| 기능 | 메서드·경로(제안) | 요청 | 응답 |
| --- | --- | --- | --- |
| 추천 | `POST /api/v1/recommendations` | (서버가 user_id로 조회) | 추천 + 근거 |

```json
{
  "status": "ok",
  "recommended_ingredients": [ {"ingredient_id":1024, "name_kor":"세라마이드", "reason":"..."} ],
  "recommended_products": [ {"product_id":77, "product_name":"..."} ]
}
```

| 확인 필요 | 내용 |
| --- | --- |
| 입력 방식 | 서버가 user_id로 프로필·BSTI·화장대 조회 vs 프론트가 body 전달 |
| 근거 미달 | `status:"insufficient_evidence"` → "확인 불가" 처리 |
| reason 노출 | 노출 정책 (RAG 문서상 일부 사유 환각 위험 → 노출 제한 여부) |

---

## 5. 확정 대기 항목 (화면 구현 전 필요)

| # | 항목 | 막히는 화면 |
| --- | --- | --- |
| 1 | API 명세서(Notion) 링크 | 전체 |
| 2 | Supabase OAuth 설정 + URL/anon key | 로그인 |
| 3 | 피부고민 표준 코드 목록 | 온보딩 |
| 4 | BSTI 문항 소스 + 채점 매핑 | BSTI |
| 5 | BSTI 결과 스키마 (+ ingredient_id) | BSTI 결과 |
| 6 | 통합 검색 API 형태 | 화장대 검색 |
| 7 | 화장대 CRUD + 점수 계산 | 나의 화장대 |
| 8 | 추천 API + reason 노출 정책 | 맞춤 추천 |

---

## 6. 신규 DB 테이블 (프론트 화면이 필요로 함)

RAG 기존 테이블(ingredients/restrictions/synonyms/product/product_ingredients/상담사례)에 더해 아래 3개가 신규 필요. 스키마·소유권(RLS)은 백엔드 담당, 프론트가 필요로 하는 최소 필드만 표기.

| 신규 테이블 | 최소 필드 | 연결 화면 |
| --- | --- | --- |
| `user_profiles` | user_id, nickname, age, gender, skin_concerns[] | 온보딩·추천 |
| `user_shelf` | id, user_id, item_type, ref_id, created_at | 나의 화장대 |
| `bsti_results` | id, user_id, type_code, axes(json), recommended/caution(json), created_at | BSTI 결과 |

> 세 테이블 모두 user_id 소유권 검사 필요. DB 세부는 차차 협의.
