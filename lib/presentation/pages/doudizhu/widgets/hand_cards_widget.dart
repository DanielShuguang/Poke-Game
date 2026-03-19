import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart' as game;
import 'package:poke_game/presentation/pages/doudizhu/doudizhu_provider.dart';
import 'package:poke_game/presentation/widgets/playing_card_widget.dart';

/// 手牌组件（支持拖拽选牌）
class HandCardsWidget extends ConsumerStatefulWidget {
  final List<game.Card> cards;
  final Set<game.Card> selectedCards;
  final bool enabled;
  final Set<game.Card>? hintCards;

  const HandCardsWidget({
    super.key,
    required this.cards,
    required this.selectedCards,
    this.enabled = true,
    this.hintCards,
  });

  @override
  ConsumerState<HandCardsWidget> createState() => _HandCardsWidgetState();
}

class _HandCardsWidgetState extends ConsumerState<HandCardsWidget> {
  /// 是否正在拖拽选牌
  bool _isDragging = false;

  /// 拖拽划过的牌（按顺序）
  List<game.Card> _draggedCardsList = [];

  /// 预览选中的牌（计算出的目标牌型）
  Set<game.Card> _previewCards = {};

  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();

  /// 全局 key 用于获取 RenderBox
  final GlobalKey _containerKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 检测位置下的卡牌
  void _detectCardsUnderPosition(Offset globalPosition) {
    final containerRenderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerRenderBox == null) return;

    final localPosition = containerRenderBox.globalToLocal(globalPosition);

    // 找出当前位置下的卡牌
    game.Card? cardUnderPosition;
    for (int i = widget.cards.length - 1; i >= 0; i--) {
      final card = widget.cards[i];
      final rect = _cachedCardRects[card];
      if (rect != null && rect.contains(localPosition)) {
        cardUnderPosition = card;
        break;
      }
    }

    if (cardUnderPosition != null) {
      final card = cardUnderPosition; // 确保 non-null
      if (!_draggedCardsList.contains(card)) {
        setState(() {
          _draggedCardsList.add(card);
          _calculatePreviewCards();
        });
      }
    }
  }

  /// 缓存的卡牌位置
  Map<game.Card, Rect> _cachedCardRects = {};

  /// 更新缓存的卡牌位置
  void _updateCachedRects() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rects = <game.Card, Rect>{};
      final containerRenderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;

      if (containerRenderBox == null) return;

      // 遍历子元素获取位置
      void visitCard(Element element) {
        if (element.widget is _DraggableCard) {
          final cardWidget = element.widget as _DraggableCard;
          final cardRenderBox = element.findRenderObject() as RenderBox?;
          if (cardRenderBox != null && cardRenderBox.hasSize) {
            final cardLocalPosition = cardRenderBox.localToGlobal(Offset.zero, ancestor: containerRenderBox);
            rects[cardWidget.card] = cardLocalPosition & cardRenderBox.size;
          }
        }
        element.visitChildElements(visitCard);
      }

      context.visitChildElements(visitCard);

      if (mounted && rects.isNotEmpty) {
        setState(() {
          _cachedCardRects = rects;
        });
      }
    });
  }

  /// 计算预览选中的牌
  void _calculatePreviewCards() {
    if (_draggedCardsList.isEmpty) {
      _previewCards = {};
      return;
    }

    final lastPlayedCards = ref.read(doudizhuProvider).gameState.lastPlayedCards;
    final validator = ref.read(doudizhuProvider.notifier).validator;

    List<game.Card>? selectedCards;

    if (lastPlayedCards == null) {
      selectedCards = validator.findBestCombination(_draggedCardsList);
    } else {
      selectedCards = validator.findMinBeatingCombination(
        _draggedCardsList,
        lastPlayedCards,
      );
    }

    _previewCards = selectedCards?.toSet() ?? {};
  }

  /// 开始拖拽
  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;

    // 更新卡牌位置缓存
    _updateCachedRects();

    setState(() {
      _isDragging = true;
      _draggedCardsList = [];
      _previewCards = {};
    });

    _detectCardsUnderPosition(event.position);
  }

  /// 拖拽移动
  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDragging || !widget.enabled) return;
    _detectCardsUnderPosition(event.position);
  }

  /// 结束拖拽
  void _onPointerUp(PointerUpEvent event) {
    if (!_isDragging) return;

    // 确认选择
    if (_previewCards.isNotEmpty) {
      ref.read(doudizhuProvider.notifier).selectCardsByDrag(_draggedCardsList);
    }

    setState(() {
      _isDragging = false;
      _draggedCardsList = [];
      _previewCards = {};
    });
  }

  /// 取消拖拽
  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _isDragging = false;
      _draggedCardsList = [];
      _previewCards = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    // 构建时更新位置缓存
    _updateCachedRects();

    return Container(
      key: _containerKey,
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Listener(
        onPointerDown: widget.enabled ? _onPointerDown : null,
        onPointerMove: widget.enabled ? _onPointerMove : null,
        onPointerUp: widget.enabled ? _onPointerUp : null,
        onPointerCancel: widget.enabled ? _onPointerCancel : null,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: _isDragging ? const NeverScrollableScrollPhysics() : null,
          child: Row(
            children: widget.cards.map((card) {
              final isSelected = widget.selectedCards.contains(card);
              final isHint = widget.hintCards?.contains(card) ?? false;

              // 拖拽预览状态
              final isDragged = _draggedCardsList.contains(card);
              final isPreview = _previewCards.contains(card);

              return _DraggableCard(
                key: ValueKey('${card.suit}_${card.rank}'),
                card: card,
                isSelected: isSelected,
                isHint: isHint && !isSelected,
                isDragged: isDragged,
                isPreview: isPreview,
                enabled: widget.enabled,
                onTap: widget.enabled
                    ? () {
                        ref
                            .read(doudizhuProvider.notifier)
                            .toggleCardSelection(card);
                      }
                    : null,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// 可追踪位置的卡牌组件
class _DraggableCard extends StatelessWidget {
  final game.Card card;
  final bool isSelected;
  final bool isHint;
  final bool isDragged;
  final bool isPreview;
  final bool enabled;
  final VoidCallback? onTap;

  const _DraggableCard({
    super.key,
    required this.card,
    required this.isSelected,
    required this.isHint,
    required this.isDragged,
    required this.isPreview,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: CardWidget(
        card: card,
        isSelected: isSelected,
        isHint: isHint,
        isPreview: isPreview && !isSelected,
        onTap: onTap,
      ),
    );
  }
}
