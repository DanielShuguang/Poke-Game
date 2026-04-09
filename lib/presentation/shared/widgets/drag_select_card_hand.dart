import 'package:flutter/material.dart';

/// 共享拖拽选牌组件
///
/// 封装指针事件监听、位置缓存、命中检测、滚动互斥等通用拖拽选牌逻辑。
/// 各游戏通过 [calculatePreview] 回调提供差异化的验证逻辑。
class DragSelectCardHand extends StatefulWidget {
  /// 卡牌数量
  final int cardCount;

  /// 是否启用交互（非本玩家回合时应设为 false）
  final bool enabled;

  /// 拖拽触发阈值（像素），移动距离超过此值才进入拖拽模式。
  /// 默认 4.0，可有效区分点击和拖拽。
  final double dragThreshold;

  /// 卡牌渲染回调，各游戏提供自己的卡牌 Widget。
  /// [isDragged] 表示该牌在当前拖拽路径中，[isPreview] 表示该牌在预览组合中。
  final Widget Function(
    int index, {
    required bool isDragged,
    required bool isPreview,
  }) cardBuilder;

  /// 预览计算回调（游戏特定验证逻辑）。
  /// 收到拖拽经过的索引列表，返回应高亮为预览的索引集合。
  final Set<int> Function(List<int> draggedIndices)? calculatePreview;

  /// 拖拽结束选中确认回调，[selectedIndices] 为预览索引集合。
  final void Function(Set<int> selectedIndices)? onDragEnd;

  /// 单击（非拖拽）回调。
  final void Function(int index)? onTap;

  /// 卡牌区域高度
  final double height;

  const DragSelectCardHand({
    super.key,
    required this.cardCount,
    this.enabled = true,
    this.dragThreshold = 4.0,
    required this.cardBuilder,
    this.calculatePreview,
    this.onDragEnd,
    this.onTap,
    this.height = 80,
  });

  @override
  State<DragSelectCardHand> createState() => _DragSelectCardHandState();
}

class _DragSelectCardHandState extends State<DragSelectCardHand> {
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

  // --------------- 位置缓存 ---------------

  /// 通过 Element 树遍历缓存每张牌的 Rect 位置
  void _updateCachedRects() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final containerBox =
          _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (containerBox == null) return;

      final rects = <int, Rect>{};

      void visit(Element element) {
        if (element.widget is _DragSelectItem) {
          final item = element.widget as _DragSelectItem;
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

  // --------------- 命中检测 ---------------

  /// 返回 [globalPos] 下的卡牌索引，重叠时取最上层（索引最大）。
  int? _cardIndexAt(Offset globalPos) {
    final containerBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerBox == null) return null;
    final local = containerBox.globalToLocal(globalPos);
    for (int i = widget.cardCount - 1; i >= 0; i--) {
      final rect = _cachedCardRects[i];
      if (rect != null && rect.contains(local)) return i;
    }
    return null;
  }

  // --------------- 指针事件 ---------------

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _updateCachedRects();
    _draggedIndices = [];
    _previewIndices = {};
    _dragStartPosition = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.enabled) return;
    if (!_isDragging) {
      final delta = (event.position - _dragStartPosition).distance;
      if (delta < widget.dragThreshold) return;
      setState(() => _isDragging = true);
    }
    final idx = _cardIndexAt(event.position);
    if (idx != null && !_draggedIndices.contains(idx)) {
      setState(() {
        _draggedIndices.add(idx);
        _previewIndices =
            widget.calculatePreview?.call(_draggedIndices) ?? {};
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isDragging) {
      // 未超过阈值：视为点击
      final idx = _cardIndexAt(event.position);
      _draggedIndices = [];
      _previewIndices = {};
      if (idx != null) {
        widget.onTap?.call(idx);
      }
      return;
    }
    // 拖拽结束
    if (_previewIndices.isNotEmpty) {
      widget.onDragEnd?.call(Set.of(_previewIndices));
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

  // --------------- 构建 ---------------

  @override
  Widget build(BuildContext context) {
    _updateCachedRects();

    return Container(
      key: _containerKey,
      height: widget.height,
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
            children: List.generate(widget.cardCount, (i) {
              final isDragged = _draggedIndices.contains(i);
              final isPreview = _previewIndices.contains(i);
              return _DragSelectItem(
                key: ValueKey(i),
                index: i,
                child: widget.cardBuilder(
                  i,
                  isDragged: isDragged,
                  isPreview: isPreview,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 标记 Widget，用于 Element 树遍历时识别卡牌位置。
class _DragSelectItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _DragSelectItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}
