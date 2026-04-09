import 'dart:math';

import 'package:flutter/foundation.dart';

import 'mcts_engine.dart';
import 'mcts_game_state.dart';

/// PIMC（Perfect Information Monte Carlo）引擎。
///
/// 通过对隐信息局面进行 [samples] 次确定性采样，在每个样本上运行 [MctsEngine]，
/// 汇总投票后返回得票最多的行动。
class PimcEngine<S extends MctsGameState<A>, A> {
  /// determinize 采样次数，默认 20。
  final int samples;

  /// 总搜索时间预算（均摊到每个样本），默认 150ms。
  final Duration timeLimit;

  /// 可插拔 rollout 策略（透传给内部每个 MctsEngine）。
  final RolloutPolicy<A>? rolloutPolicy;

  final Random _random;

  PimcEngine({
    this.samples = 20,
    this.timeLimit = const Duration(milliseconds: 150),
    this.rolloutPolicy,
    Random? random,
  }) : _random = random ?? Random();

  /// 从 [state] 出发，以 [currentPlayerId] 为当前视角执行 PIMC 搜索。
  A search(S state, String currentPlayerId) {
    final perSampleLimit =
        Duration(microseconds: timeLimit.inMicroseconds ~/ samples);

    final votes = <A, int>{};

    for (int i = 0; i < samples; i++) {
      final determinized = state.determinize(currentPlayerId) as S;
      if (determinized.isTerminal) continue;

      final engine = MctsEngine<S, A>(
        currentPlayerId: currentPlayerId,
        timeLimit: perSampleLimit,
        rolloutPolicy: rolloutPolicy,
      );

      final action = engine.search(determinized);
      votes[action] = (votes[action] ?? 0) + 1;
    }

    if (votes.isEmpty) {
      // 兜底：直接返回第一个合法行动
      return state.getLegalActions().first;
    }

    // 找最高票数
    final maxVotes = votes.values.reduce(max);
    final topActions =
        votes.entries.where((e) => e.value == maxVotes).map((e) => e.key).toList();

    // 平局时随机选取
    return topActions[_random.nextInt(topActions.length)];
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 顶层 Isolate 封装函数
// ────────────────────────────────────────────────────────────────────────────

/// PIMC 搜索的参数包装（用于 compute() 传输）。
class PimcSearchParams<S extends MctsGameState<A>, A> {
  final S state;
  final String currentPlayerId;
  final int samples;
  final Duration timeLimit;

  const PimcSearchParams({
    required this.state,
    required this.currentPlayerId,
    this.samples = 20,
    this.timeLimit = const Duration(milliseconds: 150),
  });
}

/// MCTS 搜索的参数包装（用于 compute() 传输）。
class MctsSearchParams<S extends MctsGameState<A>, A> {
  final S state;
  final String currentPlayerId;
  final Duration timeLimit;

  const MctsSearchParams({
    required this.state,
    required this.currentPlayerId,
    this.timeLimit = const Duration(milliseconds: 150),
  });
}

/// 在独立 Isolate 中执行 PIMC 搜索，返回 Future<A>，主线程不阻塞。
///
/// 注意：[params] 及其包含的所有对象必须是可序列化的纯 Dart 数据类型。
Future<A> runPimcSearch<S extends MctsGameState<A>, A>(
    PimcSearchParams<S, A> params) {
  return compute(
    _pimcSearchIsolate<S, A>,
    params,
  );
}

/// 在独立 Isolate 中执行单次 MCTS 搜索，返回 Future<A>，主线程不阻塞。
///
/// 注意：[params] 及其包含的所有对象必须是可序列化的纯 Dart 数据类型。
Future<A> runMctsSearch<S extends MctsGameState<A>, A>(
    MctsSearchParams<S, A> params) {
  return compute(
    _mctsSearchIsolate<S, A>,
    params,
  );
}

A _pimcSearchIsolate<S extends MctsGameState<A>, A>(
    PimcSearchParams<S, A> params) {
  final engine = PimcEngine<S, A>(
    samples: params.samples,
    timeLimit: params.timeLimit,
  );
  return engine.search(params.state, params.currentPlayerId);
}

A _mctsSearchIsolate<S extends MctsGameState<A>, A>(
    MctsSearchParams<S, A> params) {
  final engine = MctsEngine<S, A>(
    currentPlayerId: params.currentPlayerId,
    timeLimit: params.timeLimit,
  );
  return engine.search(params.state);
}
