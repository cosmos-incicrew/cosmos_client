// 담은 선호/기피가 화면 전환(push → pop)에도 남는지 검증.
//
// ProviderScope 가 라우터보다 위(main.dart)에 있으므로 화면을 오갔다고
// 날아가면 안 된다. 이게 깨지면 "담았는데 화장대에 없다"가 된다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('화면을 push/pop 해도 담은 항목이 남는다', (tester) async {
    late WidgetRef homeRef;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(builder: (ctx, ref, __) {
            homeRef = ref;
            return Scaffold(
              body: Builder(
                builder: (innerCtx) => ElevatedButton(
                  onPressed: () => Navigator.of(innerCtx).push(
                    MaterialPageRoute(
                      builder: (_) => Consumer(builder: (c, r, __) {
                        // 다른 화면에서 담는다.
                        return Scaffold(
                          body: ElevatedButton(
                            onPressed: () => r
                                .read(shelfPreferenceProvider.notifier)
                                .add(const ShelfEntry(
                                  id: 1,
                                  name: '토너',
                                  isProduct: true,
                                  kind: PreferenceKind.like,
                                )),
                            child: const Text('담기'),
                          ),
                        );
                      }),
                    ),
                  ),
                  child: const Text('검색으로'),
                ),
              ),
            );
          }),
        ),
      ),
    );

    // 검색 화면으로 이동해서 담고 다시 돌아온다.
    await tester.tap(find.text('검색으로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('담기'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('담기'))).pop();
    await tester.pumpAndSettle();

    // 돌아온 화면에서도 담은 게 보여야 한다.
    final kept = homeRef.read(shelfPreferenceProvider);
    expect(kept.length, 1);
    expect(kept.first.name, '토너');
    expect(kept.first.kind, PreferenceKind.like);
  });
}
