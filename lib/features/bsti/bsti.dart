/// BSTI 데이터·엔진 배럴 파일.
///
/// 한 줄로 전부 가져다 쓴다:
/// ```dart
/// import 'package:cosmos_app/features/bsti/bsti.dart';
///
/// final result = BstiEngine.diagnose(answers); // answers: {문항id: score}
/// print(result.code);                          // 'OSPW'
/// print(result.type.personaName);              // '진정이 먼저인 …'
/// print(result.recommendedIngredients);        // [BstiIngredient, …]
/// ```
///
/// 모든 데이터가 코드에 들어 있어 백엔드 호출이 없다. (프론트 전용)
library;

export 'bsti_models.dart';
export 'bsti_dataset.dart';
export 'bsti_skin_types.dart';
export 'bsti_engine.dart';
