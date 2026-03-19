/// 游戏状态枚举
enum GameStatus {
  /// 已上线
  available,

  /// 开发中
  comingSoon,

  /// 计划中
  planned,
}

/// 游戏分类枚举
enum GameCategory {
  /// 扑克牌类
  cardGames,

  /// 棋类
  boardGames,

  /// 其他
  other,
}

/// 游戏信息实体
class GameInfo {
  /// 游戏唯一标识
  final String id;

  /// 游戏名称
  final String name;

  /// 游戏描述
  final String description;

  /// 游戏图标（资源路径或网络URL）
  final String icon;

  /// 游戏状态
  final GameStatus status;

  /// 游戏分类
  final GameCategory category;

  /// 路由路径
  final String route;

  const GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.status,
    required this.category,
    required this.route,
  });
}
