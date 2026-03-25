import 'package:poke_game/domain/zhajinhua/entities/zhj_game_config.dart';
import 'package:poke_game/domain/zhajinhua/entities/zhj_game_state.dart';

abstract class ZhjGameRepository {
  /// 初始化游戏状态（创建玩家）
  ZhjGameState initGame(ZhjGameConfig config);

  /// 保存游戏状态（内存缓存）
  void saveState(ZhjGameState state);

  /// 读取最近保存的状态
  ZhjGameState? loadState();
}
