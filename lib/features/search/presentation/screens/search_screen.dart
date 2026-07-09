import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/loading_view.dart';
import '../../../product/data/models/product.dart';
import '../../../product/presentation/widgets/product_card.dart';

/// 제품명·성분명 검색 화면.
///
/// 실제 검색 API(BE 담당)는 아직 미연동입니다.
/// 현재는 샘플 데이터에 대해 로컬 필터링만 수행합니다.
/// TODO: dioProvider 를 통해 검색 API 호출로 교체.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Product> _results = const [];
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    // 로컬 목업 필터: 제품명 또는 성분명 매칭
    final results = sampleProducts.where((p) {
      final inName = p.name.contains(q);
      final inIngredient = p.ingredients.any((i) => i.contains(q));
      return inName || inIngredient;
    }).toList();
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '제품명 · 성분명 검색',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_searched) {
      return const EmptyView(
        icon: Icons.search,
        message: '제품명이나 성분명을 입력해보세요',
      );
    }
    if (_results.isEmpty) {
      return const EmptyView(
        icon: Icons.sentiment_dissatisfied_outlined,
        message: '검색 결과가 없어요',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final p = _results[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ProductCard(
            product: p,
            onTap: () => context.push('/product/${p.id}'),
          ),
        );
      },
    );
  }
}
