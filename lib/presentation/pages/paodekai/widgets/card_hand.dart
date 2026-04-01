import 'package:flutter/material.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_card.dart';
import 'package:poke_game/domain/paodekai/entities/pdk_game_state.dart';
import 'package:poke_game/domain/paodekai/usecases/validate_play_usecase.dart';
import 'package:poke_game/presentation/shared/game_colors.dart';

class CardHand extends StatefulWidget {
  final List<PdkCard> cards;
  final Set<int> selectedIndices;
  final Set<int> hintIndices;
  final bool enabled;
  final ValueChanged<int> onCardTap;
  final ValueChanged<Set<int>>? onSelectionChanged;

  const CardHand({
    super.key,
    required this.cards,
    required this.selectedIndices,
    this.hintIndices = const {},
    this.enabled = true,
    required this.onCardTap,
    this.onSelectionChanged,
  });

  @override
  State<CardHand> createState() => _CardHandState();
}

class _CardHandState extends State<CardHand> {
  static const _validate = ValidatePlayUseCase();

  bool _isDragging = false;
  List<int> _draggedIndices = [];
  Set<int> _previewIndices = {};
  Offset _dragStartPosition = Offset.zero;

  final GlobalKey _containerKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  Map<int, Rect> _cachedCardRects = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCachedRects() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final containerBox =
          _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (containerBox == null) return;

      final rects = <int, Rect>{};

      void visit(Element element) {
        if (element.widget is _CardItem) {
          final item = element.widget as _CardItem;
          final box = element.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final localPos =
                box.localToGlobal(Offset.zero, ancestor: containerBox);
            rects[item.index] = localPos & box.size;
          }
        }
        element.visitChildElements(visit);
      }

      context.visitChildElements(visit);

      if (mounted && rects.isNotEmpty) {
        setState(() => _cachedCardRects = rects);
      }
    });
  }

  int? _cardIndexAt(Offset globalPos) {
    final containerBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerBox == null) return null;
    final local = containerBox.globalToLocal(globalPos);
    // 从后往前找（上层牌优先）
    for (int i = widget.cards.length - 1; i >= 0; i--) {
      final rect = _cachedCardRects[i];
      if (rect != null && rect.contains(local)) return i;
    }
    return null;
  }

  void _calculatePreview() {
    if (_draggedIndices.isEmpty) {
      _previewIndices = {};
      return;
    }
    final draggedCards =
        _draggedIndices.map((i) => widget.cards[i]).toList();

    // 用空 state 的简化版验证：不传 state 中的 isFirstPlay/lastPlayedHand，
    // 此处只看牌型是否合法（拖拽预览不需要严格校验规则）
    final hand = _validate(
      selectedCards: draggedCards,
      state: PdkGameState(
        players: const [],
        phase: PdkGamePhase.playing,
        isFirstPlay: false,
      ),
    );
    _previewIndices = hand != null ? _draggedIndices.toSet() : {};
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _updateCachedRects();
    // 不立即标记为拖拽，等有实际移动才标记
    _draggedIndices = [];
    _previewIndices = {};
    _dragStartPosition = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.enabled) return;
    // 超过 4px 才认定为拖拽，避免轻微抖动触发拖拽
    if (!_isDragging) {
      final delta = (event.position - _dragStartPosition).distance;
      if (delta < 4.0) return;
      setState(() => _isDragging = true);
    }
    final idx = _cardIndexAt(event.position);
    if (idx != null && !_draggedIndices.contains(idx)) {
      setState(() {
        _draggedIndices.add(idx);
        _calculatePreview();
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isDragging) {
      // 纯点击：不拦截，让 GestureDetector.onTap 处理
      _draggedIndices = [];
      _previewIndices = {};
      return;
    }
    if (_previewIndices.isNotEmpty) {
      widget.onSelectionChanged?.call(Set.of(_previewIndices));
    }
    setState(() {
      _isDragging = false;
      _draggedIndices = [];
      _previewIndices = {};
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _isDragging = false;
      _draggedIndices = [];
      _previewIndices = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateCachedRects();

    return Container(
      key: _containerKey,
      height: 80,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.cards.length, (i) {
              final selected = widget.selectedIndices.contains(i);
              final isHint = widget.hintIndices.contains(i) && !selected;
              final isPreview = _previewIndices.contains(i) && !selected;
              return _CardItem(
                key: ValueKey(i),
                index: i,
                card: widget.cards[i],
                selected: selected,
                isHint: isHint,
                isPreview: isPreview,
                onTap: widget.enabled ? () => widget.onCardTap(i) : null,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final int index;
  final PdkCard card;
  final bool selected;
  final bool isHint;
  final bool isPreview;
  final VoidCallback? onTap;

  const _CardItem({
    super.key,
    required this.index,
    required this.card,
    required this.selected,
    required this.isHint,
    required this.isPreview,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        transform: Matrix4.translationValues(
            0, selected || isPreview ? -12 : 0, 0),
        child: _CardWidget(
          card: card,
          selected: selected,
          isHint: isHint,
          isPreview: isPreview,
        ),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final PdkCard card;
  final bool selected;
  final bool isHint;
  final bool isPreview;

  const _CardWidget({
    required this.card,
    required this.selected,
    required this.isHint,
    required this.isPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final isRed = card.isRed;

    Color borderColor;
    List<BoxShadow>? shadow;
    List<Color> gradientColors;

    if (selected) {
      borderColor = colors.cardSelectedGlow.withValues(alpha: 0.8);
      shadow = [
        BoxShadow(
          color: colors.cardSelectedGlow.withValues(alpha: 0.3),
          blurRadius: 6,
        ),
      ];
      gradientColors = [
        colors.primaryGreen.withValues(alpha: 0.25),
        colors.cardBg1,
      ];
    } else if (isHint) {
      borderColor = colors.accentAmber.withValues(alpha: 0.9);
      shadow = [
        BoxShadow(
          color: colors.accentAmber.withValues(alpha: 0.4),
          blurRadius: 8,
        ),
      ];
      gradientColors = [
        colors.accentAmber.withValues(alpha: 0.15),
        colors.cardBg1,
      ];
    } else if (isPreview) {
      borderColor = colors.cardSelectedGlow.withValues(alpha: 0.5);
      shadow = [
        BoxShadow(
          color: colors.cardSelectedGlow.withValues(alpha: 0.2),
          blurRadius: 4,
        ),
      ];
      gradientColors = [
        colors.primaryGreen.withValues(alpha: 0.12),
        colors.cardBg1,
      ];
    } else {
      borderColor = isRed
          ? colors.cardBorderRed.withValues(alpha: 0.7)
          : colors.cardBorderBlack.withValues(alpha: 0.5);
      gradientColors = [colors.cardBg1, colors.cardBg2];
    }

    return Container(
      width: 44,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: selected || isHint ? 1.5 : 1,
        ),
        boxShadow: shadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.suitSymbol,
            style: TextStyle(
              color: isRed ? colors.cardBorderRed : colors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            card.rankDisplay,
            style: TextStyle(
              color: isRed ? colors.cardBorderRed : colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
