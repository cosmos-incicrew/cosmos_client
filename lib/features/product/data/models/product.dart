/// 화장품 제품 모델. 서버 RAG 데이터 설계(product + product_ingredients)를 반영한다.
///
/// TODO: 실제 필드는 API 명세서 확정 후 맞춘다. 지금은 목업/샘플 기준.
class Product {
  const Product({
    required this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    this.mainCategory,
    this.subCategory,
    this.productUrl,
    this.ingredientIds = const [],
  });

  final int id; // product_id
  final String name; // product_name
  final String? brand;
  final String? imageUrl;
  final String? mainCategory; // 예: "스킨케어"
  final String? subCategory; // 예: "세럼/앰플"
  final String? productUrl;

  /// 이 제품에 포함된 성분들의 ingredient_id (product_ingredients N:M 매핑).
  final List<int> ingredientIds;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] as int,
      name: json['product_name'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String?,
      mainCategory: json['main_category'] as String?,
      subCategory: json['sub_category'] as String?,
      productUrl: json['product_url'] as String?,
      ingredientIds:
          (json['ingredient_ids'] as List?)?.cast<int>() ?? const [],
    );
  }
}

/// 개발용 샘플 데이터. API 연동 전 UI 확인에 사용 (피그마 예시 제품 반영).
const sampleProducts = <Product>[
  Product(
    id: 1,
    name: '아토베리어365 크림',
    brand: '에스트라',
    mainCategory: '스킨케어',
    subCategory: '크림',
  ),
  Product(
    id: 2,
    name: '아토베리어365 하이드로 크림',
    brand: '에스트라',
    mainCategory: '스킨케어',
    subCategory: '크림',
  ),
  Product(
    id: 3,
    name: '아토베리어365 캡슐토너',
    brand: '에스트라',
    mainCategory: '스킨케어',
    subCategory: '토너',
  ),
];
