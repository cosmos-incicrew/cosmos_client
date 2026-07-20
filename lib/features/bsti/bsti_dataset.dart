/// BSTI 공통 데이터셋 (성분 사전 · 자차 · 축 · 문항 · 근거).
///
/// Supabase 스키마의 시드 데이터를 프론트(앱)에서 바로 쓰도록 코드로 옮긴 것.
/// 백엔드 호출 없이 이 상수들만으로 진단이 완결된다.
///
/// 유형별(권장/기피 성분) 데이터는 [bsti_skin_types.dart]에,
/// 채점/조회 로직은 [bsti_engine.dart]에 있다.
library;

import 'bsti_models.dart';

/// 성분 사전. id → 성분. (bsti_ingredients: 34개)
const Map<String, BstiIngredient> kBstiIngredients = {
  // ── 권장 성분 ──
  'cera': BstiIngredient(
    id: 'cera',
    nameKo: '세라마이드',
    inci: 'Ceramide NP',
    role: '장벽 복구·경피수분손실 감소',
    category: BstiIngredientCategory.barrier,
    refCodes: ['S1', 'S2'],
  ),
  'ha': BstiIngredient(
    id: 'ha',
    nameKo: '히알루론산',
    inci: 'Sodium Hyaluronate',
    role: '수분 공급·유지',
    category: BstiIngredientCategory.humectant,
    refCodes: ['S1'],
  ),
  'panth': BstiIngredient(
    id: 'panth',
    nameKo: '판테놀',
    inci: 'Panthenol',
    role: '보습 + 진정',
    category: BstiIngredientCategory.soothing,
    refCodes: ['S4'],
  ),
  'squa': BstiIngredient(
    id: 'squa',
    nameKo: '스쿠알란',
    inci: 'Squalane',
    role: '유분 보강·건조 완화',
    category: BstiIngredientCategory.emollient,
    refCodes: ['S2'],
  ),
  'gly': BstiIngredient(
    id: 'gly',
    nameKo: '글리세린',
    inci: 'Glycerin',
    role: '수분 유지',
    category: BstiIngredientCategory.humectant,
    refCodes: ['S1'],
  ),
  'niac': BstiIngredient(
    id: 'niac',
    nameKo: '나이아신아마이드',
    inci: 'Niacinamide',
    role: '피지↓·진정·미백·항산화 (멀티벤핏)',
    category: BstiIngredientCategory.multi,
    refCodes: ['S3', 'S8'],
  ),
  'sal': BstiIngredient(
    id: 'sal',
    nameKo: '살리실산 (BHA)',
    inci: 'Salicylic Acid',
    role: '모공 각질·피지 조절',
    category: BstiIngredientCategory.exfoliant,
    refCodes: ['S10'],
  ),
  'zinc': BstiIngredient(
    id: 'zinc',
    nameKo: '아연',
    inci: 'Zinc PCA',
    role: '피지·진정 보조',
    category: BstiIngredientCategory.sebum,
    refCodes: ['S10'],
  ),
  'reti': BstiIngredient(
    id: 'reti',
    nameKo: '레티놀',
    inci: 'Retinol',
    role: '콜라겐 생성·잔주름·각질',
    category: BstiIngredientCategory.retinoid,
    refCodes: ['S6', 'S7'],
  ),
  'retal': BstiIngredient(
    id: 'retal',
    nameKo: '저농도 레티날 / 바쿠치올',
    inci: 'Retinal / Bakuchiol',
    role: '자극 적은 항노화 대안',
    category: BstiIngredientCategory.retinoid,
    refCodes: ['S6'],
  ),
  'adap': BstiIngredient(
    id: 'adap',
    nameKo: '아다팔렌',
    inci: 'Adapalene',
    role: '여드름·각질 조절',
    category: BstiIngredientCategory.retinoid,
    refCodes: ['S10'],
  ),
  'aze': BstiIngredient(
    id: 'aze',
    nameKo: '아젤라익애씨드',
    inci: 'Azelaic Acid',
    role: '여드름+진정+미백 (멀티벤핏)',
    category: BstiIngredientCategory.multi,
    refCodes: ['S11'],
  ),
  'cica': BstiIngredient(
    id: 'cica',
    nameKo: '병풀추출물',
    inci: 'Centella Asiatica Extract',
    role: '항염·진정·장벽 강화',
    category: BstiIngredientCategory.soothing,
    refCodes: ['S4', 'S9'],
  ),
  'allan': BstiIngredient(
    id: 'allan',
    nameKo: '알란토인',
    inci: 'Allantoin',
    role: '진정·보습',
    category: BstiIngredientCategory.soothing,
    refCodes: ['S4'],
  ),
  'bisa': BstiIngredient(
    id: 'bisa',
    nameKo: '비사보롤',
    inci: 'Bisabolol',
    role: '항염 진정',
    category: BstiIngredientCategory.soothing,
    refCodes: ['S9'],
  ),
  'toco': BstiIngredient(
    id: 'toco',
    nameKo: '토코페롤 (비타민E)',
    inci: 'Tocopherol',
    role: '항산화 진정',
    category: BstiIngredientCategory.antioxidant,
    refCodes: ['S12'],
  ),
  'vc': BstiIngredient(
    id: 'vc',
    nameKo: '비타민C',
    inci: 'Ascorbic Acid',
    role: '미백 + 콜라겐 합성',
    category: BstiIngredientCategory.multi,
    refCodes: ['S12'],
  ),
  'vcd': BstiIngredient(
    id: 'vcd',
    nameKo: '비타민C 유도체',
    inci: 'Tetrahexyldecyl Ascorbate',
    role: '저자극 미백·항산화',
    category: BstiIngredientCategory.multi,
    refCodes: ['S12'],
  ),
  'txa': BstiIngredient(
    id: 'txa',
    nameKo: '트라넥사믹애씨드',
    inci: 'Tranexamic Acid',
    role: '색소침착 감소',
    category: BstiIngredientCategory.brightening,
    refCodes: ['S5'],
  ),
  'arb': BstiIngredient(
    id: 'arb',
    nameKo: '알부틴',
    inci: 'Arbutin',
    role: '티로시나제 억제 미백',
    category: BstiIngredientCategory.brightening,
    refCodes: ['S3'],
  ),
  'lico': BstiIngredient(
    id: 'lico',
    nameKo: '감초추출물',
    inci: 'Glycyrrhiza Glabra Extract',
    role: '미백·항염',
    category: BstiIngredientCategory.brightening,
    refCodes: ['S3'],
  ),
  'pept': BstiIngredient(
    id: 'pept',
    nameKo: '펩타이드',
    inci: 'Peptides',
    role: '콜라겐 보조·탄력',
    category: BstiIngredientCategory.antiaging,
    refCodes: ['S3'],
  ),
  'feru': BstiIngredient(
    id: 'feru',
    nameKo: '페룰산',
    inci: 'Ferulic Acid',
    role: '항산화·비타민C 안정화',
    category: BstiIngredientCategory.antioxidant,
    refCodes: ['S3'],
  ),
  // ── 기피 성분 ──
  'coconut': BstiIngredient(
    id: 'coconut',
    nameKo: '코코넛오일',
    inci: 'Cocos Nucifera Oil',
    role: '모공을 막을 수 있음(코메도제닉)',
    category: BstiIngredientCategory.comedogenic,
  ),
  'ipm': BstiIngredient(
    id: 'ipm',
    nameKo: '이소프로필미리스테이트',
    inci: 'Isopropyl Myristate',
    role: '코메도제닉',
    category: BstiIngredientCategory.comedogenic,
  ),
  'lanolin': BstiIngredient(
    id: 'lanolin',
    nameKo: '라놀린',
    inci: 'Lanolin',
    role: '코메도제닉',
    category: BstiIngredientCategory.comedogenic,
  ),
  'alcohol_hi': BstiIngredient(
    id: 'alcohol_hi',
    nameKo: '고농도 변성알코올',
    inci: 'Alcohol Denat.',
    role: '건조·장벽 손상',
    category: BstiIngredientCategory.irritant,
  ),
  'sls': BstiIngredient(
    id: 'sls',
    nameKo: '소듐라우릴설페이트',
    inci: 'Sodium Lauryl Sulfate',
    role: '강한 세정력으로 장벽 손상',
    category: BstiIngredientCategory.irritant,
  ),
  'fragrance': BstiIngredient(
    id: 'fragrance',
    nameKo: '향료',
    inci: 'Fragrance/Parfum',
    role: '자극·알레르기 유발',
    category: BstiIngredientCategory.irritant,
  ),
  'essoil': BstiIngredient(
    id: 'essoil',
    nameKo: '에센셜오일',
    inci: 'Essential Oils',
    role: '자극 유발 가능',
    category: BstiIngredientCategory.irritant,
  ),
  'bpo': BstiIngredient(
    id: 'bpo',
    nameKo: '벤조일퍼옥사이드',
    inci: 'Benzoyl Peroxide',
    role: '민감성에 자극',
    category: BstiIngredientCategory.irritant,
  ),
  'glycolic': BstiIngredient(
    id: 'glycolic',
    nameKo: '글리콜산',
    inci: 'Glycolic Acid',
    role: '민감성에 자극(고농도 AHA)',
    category: BstiIngredientCategory.irritant,
  ),
  'reti_hi': BstiIngredient(
    id: 'reti_hi',
    nameKo: '고농도 트레티노인/레티놀',
    inci: 'High-dose Tretinoin/Retinol',
    role: '민감성에 자극',
    category: BstiIngredientCategory.irritant,
  ),
  'chem_filter': BstiIngredient(
    id: 'chem_filter',
    nameKo: '화학필터',
    inci: 'Oxybenzone/Octinoxate',
    role: '접촉 자극·알레르기',
    category: BstiIngredientCategory.irritant,
  ),
};

/// 자외선차단제 유형. id → 자차. (bsti_sunscreens: 6개)
const Map<String, BstiSunscreen> kBstiSunscreens = {
  'tint': BstiSunscreen(
    id: 'tint',
    nameKo: '징크옥사이드 + 아이언옥사이드 (틴티드, 젤)',
    note: 'UV·가시광선 차단 → 색소 재발 예방',
    refCodes: ['S13', 'S14'],
  ),
  'tintCream': BstiSunscreen(
    id: 'tintCream',
    nameKo: '징크옥사이드 + 아이언옥사이드 (틴티드, 크림)',
    note: '건성+색소용, 가시광선 차단·보습',
    refCodes: ['S13', 'S14'],
  ),
  'mineral': BstiSunscreen(
    id: 'mineral',
    nameKo: '무기자차 (징크옥사이드·티타늄디옥사이드)',
    note: '민감성 저자극·광안정',
    refCodes: ['S15'],
  ),
  'mineralGel': BstiSunscreen(
    id: 'mineralGel',
    nameKo: '무기자차 (젤 제형)',
    note: '지성+민감용 저자극',
    refCodes: ['S15'],
  ),
  'organic': BstiSunscreen(
    id: 'organic',
    nameKo: '유기자차 (젤/플루이드)',
    note: '백탁 없고 발림성 우수',
    refCodes: ['S15'],
  ),
  'basic': BstiSunscreen(
    id: 'basic',
    nameKo: '보습형 광범위 자차',
    note: '제형 무관, 예방 중심',
    refCodes: ['S14'],
  ),
};

/// 근거 논문. code → 참조. (bsti_references: 15개)
const Map<String, BstiReference> kBstiReferences = {
  'S1': BstiReference(
    code: 'S1',
    title: '세라마이드 장벽복구 (Cosmoderma 2024)',
    url:
        'https://cosmoderma.org/clinical-evaluation-of-a-topical-ceramide-lotion-on-skin-hydration-and-skin-barrier-in-healthy-volunteers-with-dry-skin/',
  ),
  'S2': BstiReference(
    code: 'S2',
    title: '세라마이드 지질기전 (PMC5801391)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC5801391/',
  ),
  'S3': BstiReference(
    code: 'S3',
    title: '나이아신아마이드 미백·항노화 (Antioxidants 2021)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC8389214/',
  ),
  'S4': BstiReference(
    code: 'S4',
    title: '병풀+세라마이드 민감성 (JCD 2025)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC12274965/',
  ),
  'S5': BstiReference(
    code: 'S5',
    title: '트라넥사믹+나이아신아마이드 RCT (Sci Rep 2025)',
    url: 'https://www.nature.com/articles/s41598-025-26693-8',
  ),
  'S6': BstiReference(
    code: 'S6',
    title: '트레티노인 광노화 리뷰 (PMC9112391)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC9112391/',
  ),
  'S7': BstiReference(
    code: 'S7',
    title: '트레티노인 메타분석 (DPC 2025)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC12615114/',
  ),
  'S8': BstiReference(
    code: 'S8',
    title: '나이아신아마이드 다기능 (PMC11047333)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11047333/',
  ),
  'S9': BstiReference(
    code: 'S9',
    title: '병풀 피부질환 기전 (PMC8627341)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC8627341/',
  ),
  'S10': BstiReference(
    code: 'S10',
    title: '여드름 국소치료 리뷰 (PMC11081083)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11081083/',
  ),
  'S11': BstiReference(
    code: 'S11',
    title: '아젤라익애씨드 리뷰 (PMC12472904)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC12472904/',
  ),
  'S12': BstiReference(
    code: 'S12',
    title: '비타민C 피부건강 (PMC5579659)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC5579659/',
  ),
  'S13': BstiReference(
    code: 'S13',
    title: '틴티드 자차 기미 RCT (PMC12475913)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC12475913/',
  ),
  'S14': BstiReference(
    code: 'S14',
    title: '기미 맞춤 광보호 (PMC9790748)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC9790748/',
  ),
  'S15': BstiReference(
    code: 'S15',
    title: '무기자차 안전성 (PMC7479990)',
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC7479990/',
  ),
};

/// 평가 축 4개. (bsti_axes)
/// cutoff = 2.5 × questionCount. 축 점수합이 cutoff 이상이면 high_pole.
/// 진단 코드는 이 순서(oil→sensitivity→pigment→aging)로 조합된다.
const List<BstiAxis> kBstiAxes = [
  BstiAxis(
    code: 'oil',
    label: '유·수분',
    highPole: 'O',
    highLabel: '지성',
    lowPole: 'D',
    lowLabel: '건성',
    questionCount: 5,
    cutoff: 12.5,
  ),
  BstiAxis(
    code: 'sensitivity',
    label: '민감도',
    highPole: 'S',
    highLabel: '민감',
    lowPole: 'R',
    lowLabel: '저항',
    questionCount: 6,
    cutoff: 15.0,
  ),
  BstiAxis(
    code: 'pigment',
    label: '색소',
    highPole: 'P',
    highLabel: '색소',
    lowPole: 'N',
    lowLabel: '비색소',
    questionCount: 4,
    cutoff: 10.0,
  ),
  BstiAxis(
    code: 'aging',
    label: '노화',
    highPole: 'W',
    highLabel: '주름',
    lowPole: 'T',
    lowLabel: '탱탱',
    questionCount: 5,
    cutoff: 12.5,
  ),
];

/// 진단 문항 20개 + 보기. (bsti_questions / bsti_question_options)
/// score 4 = 높은 극(O/S/P/W) 쪽.
const List<BstiQuestion> kBstiQuestions = [
  // ── oil (5) ──
  BstiQuestion(
    id: 1,
    axisCode: 'oil',
    position: 1,
    text: '세안 후 아무것도 안 바르고 2~3시간 뒤, T존(이마·코)은?',
    options: [
      BstiOption(label: '번들거려요', score: 4, position: 1),
      BstiOption(label: '약간 유분이 돌아요', score: 3, position: 2),
      BstiOption(label: '별 변화 없어요', score: 2, position: 3),
      BstiOption(label: '당기고 건조해요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 2,
    axisCode: 'oil',
    position: 2,
    text: '모공은 어떤 편인가요?',
    options: [
      BstiOption(label: '크고 잘 보여요', score: 4, position: 1),
      BstiOption(label: '코 주변만 보여요', score: 3, position: 2),
      BstiOption(label: '거의 안 보여요', score: 2, position: 3),
      BstiOption(label: '아주 작아요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 3,
    axisCode: 'oil',
    position: 3,
    text: '보습제를 안 발라도 피부가 편한가요?',
    options: [
      BstiOption(label: '안 발라도 편해요', score: 4, position: 1),
      BstiOption(label: '가끔 당겨요', score: 3, position: 2),
      BstiOption(label: '자주 당겨요', score: 2, position: 3),
      BstiOption(label: '항상 당기고 각질이 일어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 4,
    axisCode: 'oil',
    position: 4,
    text: '오후가 되면 얼굴 전체가?',
    options: [
      BstiOption(label: '번들거려요', score: 4, position: 1),
      BstiOption(label: 'T존만 번들거려요', score: 3, position: 2),
      BstiOption(label: '그대로예요', score: 2, position: 3),
      BstiOption(label: '더 건조해져요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 5,
    axisCode: 'oil',
    position: 5,
    text: '피부 표면을 만지면?',
    options: [
      BstiOption(label: '매끈하고 촉촉해요', score: 4, position: 1),
      BstiOption(label: '보통이에요', score: 3, position: 2),
      BstiOption(label: '약간 까슬해요', score: 2, position: 3),
      BstiOption(label: '거칠고 푸석해요', score: 1, position: 4),
    ],
  ),
  // ── sensitivity (6) ──
  BstiQuestion(
    id: 6,
    axisCode: 'sensitivity',
    position: 6,
    text: '최근 4주간 홍조·따가움·발진 같은 자극 증상이 있었나요?',
    options: [
      BstiOption(label: '자주 있었어요', score: 4, position: 1),
      BstiOption(label: '가끔 있었어요', score: 3, position: 2),
      BstiOption(label: '드물었어요', score: 2, position: 3),
      BstiOption(label: '전혀 없었어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 7,
    axisCode: 'sensitivity',
    position: 7,
    text: '새 스킨케어를 쓰면 붉어지거나 따가운가요?',
    options: [
      BstiOption(label: '항상 그래요', score: 4, position: 1),
      BstiOption(label: '자주 그래요', score: 3, position: 2),
      BstiOption(label: '가끔요', score: 2, position: 3),
      BstiOption(label: '거의 없어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 8,
    axisCode: 'sensitivity',
    position: 8,
    text: '향료·에센셜오일이 든 제품을 쓰면?',
    options: [
      BstiOption(label: '자극·발진이 생겨요', score: 4, position: 1),
      BstiOption(label: '가끔 불편해요', score: 3, position: 2),
      BstiOption(label: '괜찮은 편이에요', score: 2, position: 3),
      BstiOption(label: '전혀 문제없어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 9,
    axisCode: 'sensitivity',
    position: 9,
    text: '여드름·뾰루지가 나는 편인가요?',
    options: [
      BstiOption(label: '자주 나요', score: 4, position: 1),
      BstiOption(label: '가끔 나요', score: 3, position: 2),
      BstiOption(label: '드물어요', score: 2, position: 3),
      BstiOption(label: '거의 안 나요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 10,
    axisCode: 'sensitivity',
    position: 10,
    text: '레티놀·산(AHA/BHA) 성분에 반응한 적이 있나요?',
    options: [
      BstiOption(label: '여러 번 있어요', score: 4, position: 1),
      BstiOption(label: '한두 번요', score: 3, position: 2),
      BstiOption(label: '잘 모르겠어요', score: 2, position: 3),
      BstiOption(label: '없어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 11,
    axisCode: 'sensitivity',
    position: 11,
    text: '피부과에서 민감성·주사(홍조)·아토피 얘기를 들은 적이?',
    options: [
      BstiOption(label: '진단받았어요', score: 4, position: 1),
      BstiOption(label: '의심된다 들었어요', score: 3, position: 2),
      BstiOption(label: '아니요', score: 2, position: 3),
      BstiOption(label: '전혀요', score: 1, position: 4),
    ],
  ),
  // ── pigment (4) ──
  BstiQuestion(
    id: 12,
    axisCode: 'pigment',
    position: 12,
    text: '잡티·기미·주근깨가 있나요?',
    options: [
      BstiOption(label: '많아요', score: 4, position: 1),
      BstiOption(label: '보통이에요', score: 3, position: 2),
      BstiOption(label: '조금 있어요', score: 2, position: 3),
      BstiOption(label: '거의 없어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 13,
    axisCode: 'pigment',
    position: 13,
    text: '여드름·상처 후 갈색 자국(색소침착)이?',
    options: [
      BstiOption(label: '오래 남아요', score: 4, position: 1),
      BstiOption(label: '한동안 남아요', score: 3, position: 2),
      BstiOption(label: '금방 옅어져요', score: 2, position: 3),
      BstiOption(label: '거의 안 남아요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 14,
    axisCode: 'pigment',
    position: 14,
    text: '햇볕을 쬐면 피부가?',
    options: [
      BstiOption(label: '쉽게 검어져요', score: 4, position: 1),
      BstiOption(label: '조금 검어져요', score: 3, position: 2),
      BstiOption(label: '별로 안 변해요', score: 2, position: 3),
      BstiOption(label: '거의 그대로예요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 15,
    axisCode: 'pigment',
    position: 15,
    text: '다크스팟·톤을 개선하고 싶나요?',
    options: [
      BstiOption(label: '톤이 고르지 않아 꼭 개선하고 싶어요', score: 4, position: 1),
      BstiOption(label: '개선하고 싶은 편이에요', score: 3, position: 2),
      BstiOption(label: '별로 신경 안 써요', score: 2, position: 3),
      BstiOption(label: '톤이 고르고 필요 없어요', score: 1, position: 4),
    ],
  ),
  // ── aging (5) ──
  BstiQuestion(
    id: 16,
    axisCode: 'aging',
    position: 16,
    text: '표정을 풀어도 잔주름이 보이나요?',
    options: [
      BstiOption(label: '뚜렷하게 보여요', score: 4, position: 1),
      BstiOption(label: '조금 보여요', score: 3, position: 2),
      BstiOption(label: '미세하게요', score: 2, position: 3),
      BstiOption(label: '없어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 17,
    axisCode: 'aging',
    position: 17,
    text: '눈가·이마·팔자에 주름이?',
    options: [
      BstiOption(label: '깊어요', score: 4, position: 1),
      BstiOption(label: '보이기 시작했어요', score: 3, position: 2),
      BstiOption(label: '미세해요', score: 2, position: 3),
      BstiOption(label: '없어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 18,
    axisCode: 'aging',
    position: 18,
    text: '자외선 노출과 자차(선크림) 습관은?',
    options: [
      BstiOption(label: '노출 많고 자차를 거의 안 발라요', score: 4, position: 1),
      BstiOption(label: '노출 있고 가끔 발라요', score: 3, position: 2),
      BstiOption(label: '실내 위주에 자주 발라요', score: 2, position: 3),
      BstiOption(label: '실내 위주에 매일 꼼꼼히 발라요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 19,
    axisCode: 'aging',
    position: 19,
    text: '흡연·수면부족·불규칙한 식습관 등 노화에 안 좋은 습관이?',
    options: [
      BstiOption(label: '여러 개 해당돼요', score: 4, position: 1),
      BstiOption(label: '한두 개 있어요', score: 3, position: 2),
      BstiOption(label: '거의 없어요', score: 2, position: 3),
      BstiOption(label: '전혀 없어요', score: 1, position: 4),
    ],
  ),
  BstiQuestion(
    id: 20,
    axisCode: 'aging',
    position: 20,
    text: '피부 탄력·처짐은 어떤가요?',
    options: [
      BstiOption(label: '눈에 띄게 떨어졌어요', score: 4, position: 1),
      BstiOption(label: '약간 떨어졌어요', score: 3, position: 2),
      BstiOption(label: '거의 그대로예요', score: 2, position: 3),
      BstiOption(label: '탄탄해요', score: 1, position: 4),
    ],
  ),
];
