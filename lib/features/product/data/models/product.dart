/// 화장품 제품 모델.
///
/// 지금은 목업/샘플용 최소 필드만 정의합니다.
/// 실제 API 스키마(BE 담당)가 확정되면 fromJson/toJson 을 맞춰주세요.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    this.imageUrl,
    this.category,
    this.ingredients = const [],
    this.safetyScore,
  });

  final String id;
  final String name;
  final String brand;
  final String? imageUrl;
  final String? category;

  /// 성분명 리스트 (cosmos 성분 기반 추천의 핵심 데이터)
  final List<String> ingredients;

  /// 0~100 성분 안전도 점수 (샘플)
  final int? safetyScore;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: (json['brand'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      ingredients: (json['ingredients'] as List?)?.cast<String>() ?? const [],
      safetyScore: json['safety_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'image_url': imageUrl,
        'category': category,
        'ingredients': ingredients,
        'safety_score': safetyScore,
      };
}

/// 개발용 샘플 데이터. API 연동 전 UI 확인에 사용합니다.
const sampleProducts = <Product>[
  Product(
    id: '1',
    name: '수분 진정 토너',
    brand: 'cosmos',
    category: '토너',
    ingredients: ['정제수', '나이아신아마이드', '판테놀', '히알루론산'],
    safetyScore: 92,
  ),
  Product(
    id: '2',
    name: '데일리 선크림 SPF50+',
    brand: 'cosmos',
    category: '선케어',
    ingredients: ['징크옥사이드', '나이아신아마이드', '병풀추출물'],
    safetyScore: 85,
  ),
  Product(
    id: '3',
    name: '레티놀 나이트 세럼',
    brand: 'cosmos',
    category: '세럼',
    ingredients: ['레티놀', '토코페롤', '스쿠알란'],
    safetyScore: 74,
  ),
];
