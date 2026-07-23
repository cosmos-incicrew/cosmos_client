# API 연동 계약 (프론트 → 백엔드)

> 이 문서는 프론트 화면이 필요로 하는 **목표 계약**입니다. 실행 중인 개발 API에 이미
> 모두 구현되어 있다는 뜻은 아닙니다. 현재 서버와의 차이, 실행 설정, 인증 연결 순서는
> [백엔드 연결 가이드](backend-connection.md)를 먼저 확인하세요.

프론트(`cosmos_client`)에는 **데이터가 없다.** 화면은 저장소(repository)만 보고,
저장소는 지금 빈 결과를 돌려준다. 백엔드(`cosmos_server`)가 붙으면
**아래 메서드들의 본문만** 채우면 연동이 끝난다 — 화면 코드는 손대지 않는다.

연동 지점 전체 목록:

```bash
grep -rn "TODO(BE)" lib/
```

---

## 1. 제품 — `lib/features/product/data/product_repository.dart`

| 메서드 | 엔드포인트(제안) | 용도 |
|---|---|---|
| `search(query)` | `GET /products/search?q=` | 검색 화면 |
| `listAll()` | `GET /products` | 맞춤 추천 |
| `getByIngredient(id)` | `GET /ingredients/{id}/products` | 성분 상세 "이 성분이 든 제품" |
| `findByBstiIngredient(bstiId, exclude, limit)` | `GET /products?bsti_ingredient=&limit=` | 보고서 "이 제품을 추천해요" |

**제품 응답 스키마** (`Product.fromJson` 기준):

```json
{
  "product_id": 1,
  "product_name": "아토베리어365 크림",
  "brand": "에스트라",
  "main_category": "스킨케어",
  "sub_category": "크림",
  "image_url": "https://...",
  "product_url": "https://...",
  "ingredient_ids": [101, 102, 103]
}
```

- `sub_category` 는 추천 화면의 묶음 기준이다. 표기를 통일할 것
  (앱이 아는 값: `토너` · `세럼/앰플` · `에센스` · `로션` · `크림` · `선크림`).
  모르는 값이 오면 그 제품은 추천 화면에 안 나온다.
- `brand`, `image_url`, `product_url` 은 null 허용.

---

## 2. 성분 — `lib/features/ingredient/data/ingredient_repository.dart`

| 메서드 | 엔드포인트(제안) | 용도 |
|---|---|---|
| `search(query)` | `GET /ingredients/search?q=` | 검색 화면 |
| `getByIds(ids)` | `GET /ingredients?ids=101,102` | 제품 상세 성분 목록 |
| `bstiIdsByProducts(productIds)` | `GET /products/bsti-ingredients?product_ids=1,2` | 보고서 적합도 계산 |

**성분 응답 스키마** (`Ingredient.fromJson` 기준):

```json
{
  "ingredient_id": 101,
  "name_kor": "글리세린",
  "name_eng": "Glycerin",
  "efficacy": "수분 공급·유지",
  "recommended_skin_type": "모든 피부",
  "bsti_ingredient_id": "gly"
}
```

- `ingredient_id` · `name_eng` 만 필수. 나머지는 null 허용
  (`name_kor` 이 없으면 화면에 영문명이 뜬다).
- 선택 필드도 파싱된다: `product_property` · `origin_definition` ·
  `source_ref` · `restrictions`(객체). 전체는 `Ingredient.fromJson` 참고.

**`bstiIdsByProducts` 응답:**

```json
{ "1": ["cera", "gly"], "2": ["cica"] }
```

---

## ⚠️ 놓치기 쉬운 두 가지

### 1) `getByIds` 는 **요청 순서를 지켜야 한다**

제품 상세는 받은 성분 목록의 **앞 3개를 "대표성분"으로** 보여준다.
SQL `WHERE id IN (...)` 은 순서를 보장하지 않으므로, 순서가 섞이면
대표성분이 조용히 바뀐다(에러도 안 난다).

서버에서 요청 순서대로 정렬하거나, 클라이언트에서 다시 정렬할 것.

### 2) `bsti_ingredient_id` 가 BSTI 기능의 연결고리다

이 값이 없으면 보고서 적합도와 추천이 **조용히 빈 화면**이 된다.
앱이 아는 id는 `lib/features/bsti/bsti_dataset.dart` 의 `kBstiIngredients`
키 34개다 (`cera`, `ha`, `niac`, `cica`, `panth`, `sal`, `retal` 등).
사전에 없는 값을 보내면 그 성분은 무시된다.

> BSTI 데이터(성분 34개 · 유형 16개 · 문항 25개)는 **프론트가 들고 있다.**
> 백엔드가 내려줄 필요가 없다. 서버는 제품·성분만 주면 되고,
> 연결은 `bsti_ingredient_id` 하나로 이뤄진다.

---

## 인증

`AuthRepository` (`lib/features/auth/data/auth_repository.dart`)
- 게스트 로그인만 동작한다 (로컬 세션).
- 카카오·네이버·구글·애플은 전부 `UnimplementedError` — SDK 연동 후 구현.

---

## 테스트에서 쓰는 가짜 저장소

`test/support/fake_repositories.dart` 에 작은 샘플 데이터와
`FakeProductRepository` / `FakeIngredientRepository` 가 있다.
프로바이더를 override 해서 쓴다:

```dart
final container = ProviderContainer(overrides: fakeRepos);
```

**앱 코드(`lib/`)에는 샘플 데이터를 두지 않는다.** 실데이터는 백엔드가 준다.
