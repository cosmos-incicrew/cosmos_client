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
    this.imageAsset,
  });

  final int id; // product_id
  final String name; // product_name
  final String? brand;
  final String? imageUrl;

  /// 로컬 제품 이미지 경로 (예: 'assets/images/product/p1.png').
  /// 목데이터/직접 확보한 이미지용. 네트워크 [imageUrl]보다 우선 표시한다.
  final String? imageAsset;
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

// 제품 데이터는 ProductRepository 에서 가져온다 (product_repository.dart).
