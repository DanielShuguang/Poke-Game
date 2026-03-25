import 'package:flutter/material.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_game_state.dart';
import 'package:poke_game/domain/texas_holdem/entities/holdem_player.dart';

/// 投注操作区 Widget
/// Fold / Check / Call / Raise 按钮 + Raise 金额滑动条
class BettingActionWidget extends StatefulWidget {
  final HoldemGameState state;
  final HoldemPlayer player;
  final VoidCallback onFold;
  final VoidCallback onCheck;
  final VoidCallback onCall;
  final void Function(int amount) onRaise;
  final VoidCallback onAllIn;

  const BettingActionWidget({
    super.key,
    required this.state,
    required this.player,
    required this.onFold,
    required this.onCheck,
    required this.onCall,
    required this.onRaise,
    required this.onAllIn,
  });

  @override
  State<BettingActionWidget> createState() => _BettingActionWidgetState();
}

class _BettingActionWidgetState extends State<BettingActionWidget> {
  bool _showRaiseSlider = false;
  late double _raiseValue;

  @override
  void initState() {
    super.initState();
    _raiseValue = _minRaiseBet.toDouble();
  }

  /// 最小 Raise 总注额
  int get _minRaiseBet =>
      widget.state.currentBet + widget.state.minRaise;

  /// 最大注额（All-in）
  int get _maxBet =>
      widget.player.currentBet + widget.player.chips;

  /// 能否 Check
  bool get _canCheck =>
      widget.player.currentBet >= widget.state.currentBet;

  /// 能否 Raise
  bool get _canRaise => _minRaiseBet <= _maxBet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主操作按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                label: '弃牌',
                color: Colors.red.shade700,
                onPressed: widget.onFold,
              ),
              _ActionButton(
                label: _canCheck ? '过牌' : '跟注 ${widget.state.currentBet - widget.player.currentBet}',
                color: Colors.blue.shade700,
                onPressed: _canCheck ? widget.onCheck : widget.onCall,
              ),
              if (_canRaise)
                _ActionButton(
                  label: '加注',
                  color: Colors.green.shade700,
                  onPressed: () {
                    setState(() {
                      _showRaiseSlider = !_showRaiseSlider;
                      _raiseValue = _minRaiseBet.toDouble();
                    });
                  },
                ),
              _ActionButton(
                label: 'All-In',
                color: Colors.orange.shade700,
                onPressed: widget.onAllIn,
              ),
            ],
          ),
          // Raise 滑动条
          if (_showRaiseSlider && _canRaise) ...[
            const SizedBox(height: 8),
            _RaiseSlider(
              min: _minRaiseBet.toDouble(),
              max: _maxBet.toDouble(),
              value: _raiseValue,
              totalPot: widget.state.totalPot,
              onChanged: (v) => setState(() => _raiseValue = v),
              onConfirm: () {
                widget.onRaise(_raiseValue.round());
                setState(() => _showRaiseSlider = false);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _RaiseSlider extends StatelessWidget {
  final double min;
  final double max;
  final double value;
  final int totalPot;
  final ValueChanged<double> onChanged;
  final VoidCallback onConfirm;

  const _RaiseSlider({
    required this.min,
    required this.max,
    required this.value,
    required this.totalPot,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final halfPot = (totalPot * 0.5).round().clamp(min.round(), max.round());
    final fullPot = totalPot.clamp(min.round(), max.round());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 快捷按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QuickBetButton('0.5x 底池', halfPot, onChanged),
            _QuickBetButton('1x 底池', fullPot, onChanged),
            _QuickBetButton('All-in', max.round(), onChanged),
          ],
        ),
        // 滑动条
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / 10).round().clamp(1, 200),
          label: value.round().toString(),
          activeColor: Colors.amber,
          onChanged: onChanged,
        ),
        // 确认按钮
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
          ),
          child: Text('确认加注 ${value.round()}'),
        ),
      ],
    );
  }
}

class _QuickBetButton extends StatelessWidget {
  final String label;
  final int amount;
  final ValueChanged<double> onChanged;

  const _QuickBetButton(this.label, this.amount, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => onChanged(amount.toDouble()),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.amber,
        side: const BorderSide(color: Colors.amber),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
