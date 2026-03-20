import 'package:logger/logger.dart';
import 'package:poke_game/domain/doudizhu/entities/card.dart';
import 'package:poke_game/domain/doudizhu/entities/game_config.dart';
import 'package:poke_game/domain/doudizhu/entities/game_state.dart';
import 'package:poke_game/domain/doudizhu/entities/player.dart';
import 'package:poke_game/domain/doudizhu/entities/player_interface.dart';
import 'package:poke_game/domain/lan/entities/player_identity.dart';
import 'package:uuid/uuid.dart';

/// 游戏初始化服务
///
/// 根据游戏模式创建适当的玩家实例
class GameInitializationService {
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  /// 创建单机模式玩家
  List<PlayerInterface> createSinglePlayerPlayers({
    required String humanPlayerName,
    required Future<PlayDecision> Function(List<Card>? lastPlayedCards, int? lastPlayerIndex) aiDecidePlay,
    required Future<CallDecision> Function() aiDecideCall,
  }) {
    final humanPlayer = LocalAIPlayer(
      id: _uuid.v4(),
      name: humanPlayerName,
      decidePlayCallback: (lastPlayedCards, lastPlayerIndex) async {
        // 人类玩家由 UI 触发决策，这里返回占位符
        return PlayDecision.pass();
      },
      decideCallCallback: () async {
        // 人类玩家由 UI 触发决策
        return CallDecision.pass();
      },
    );

    final aiPlayer1 = LocalAIPlayer(
      id: _uuid.v4(),
      name: 'AI 1',
      decidePlayCallback: aiDecidePlay,
      decideCallCallback: aiDecideCall,
    );

    final aiPlayer2 = LocalAIPlayer(
      id: _uuid.v4(),
      name: 'AI 2',
      decidePlayCallback: aiDecidePlay,
      decideCallCallback: aiDecideCall,
    );

    _logger.i('创建单机模式玩家: 1 人类 + 2 AI');
    return [humanPlayer, aiPlayer1, aiPlayer2];
  }

  /// 创建局域网模式玩家（房主端）
  List<PlayerInterface> createLanModePlayers({
    required List<PlayerIdentity> playerIdentities,
    required void Function(String playerId, String action, Map<String, dynamic> data) sendToPlayer,
  }) {
    if (playerIdentities.length != 3) {
      throw ArgumentError('斗地主需要 3 名玩家');
    }

    final players = playerIdentities.map((identity) {
      return RemotePlayer(
        id: identity.playerId,
        name: identity.playerName,
        sendAction: (action, data) => sendToPlayer(identity.playerId, action, data),
      );
    }).toList();

    _logger.i('创建局域网模式玩家: ${players.length} 名远程玩家');
    return players;
  }

  /// 创建游戏状态
  GameState createInitialGameState({
    required GameConfig config,
    required List<PlayerInterface> players,
  }) {
    if (players.length != config.playerCount) {
      throw ArgumentError('玩家数量与配置不符');
    }

    _logger.i('创建初始游戏状态, 模式: ${config.gameMode}');
    return GameState.initial().copyWith(
      players: players,
    );
  }

  /// 验证游戏配置
  bool validateConfig(GameConfig config) {
    if (config.playerCount != 3) {
      _logger.e('斗地主固定需要 3 名玩家');
      return false;
    }

    if (config.isLanMode && config.roomId == null) {
      _logger.e('局域网模式需要房间 ID');
      return false;
    }

    if (config.isLanMode && config.currentPlayerId == null) {
      _logger.e('局域网模式需要当前玩家 ID');
      return false;
    }

    return true;
  }
}
