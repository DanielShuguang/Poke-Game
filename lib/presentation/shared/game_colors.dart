// lib/presentation/shared/game_colors.dart
import 'package:flutter/material.dart';

class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.bgBase,
    required this.bgSurface,
    required this.bgTable,
    required this.primaryGreen,
    required this.accentAmber,
    required this.dangerRed,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg1,
    required this.cardBg2,
    required this.cardBorderRed,
    required this.cardBorderBlack,
    required this.cardBorderGold,
    required this.cardSelectedGlow,
    required this.cardBackBg,
    required this.tableGradient,
    required this.lanCardGradient,
    required this.statusInfoColor,
    required this.statusInfoBg,
    required this.statusErrorBg,
    required this.statusSuccessBg,
    required this.accentAmberBg,
    required this.teamColor,
    required this.overlay,
    required this.progressTrackBg,
  });

  // ── 背景层 ──────────────────────────────────────
  /// Scaffold 基础背景
  final Color bgBase;

  /// 面板、信息卡片背景
  final Color bgSurface;

  /// 游戏桌面背景（保留绿色感）
  final Color bgTable;

  // ── 主色调 ──────────────────────────────────────
  /// 主操作按钮（出牌、确认）
  final Color primaryGreen;

  /// 强调色（庄家标记、积分高亮）
  final Color accentAmber;

  /// 危险/退出确认
  final Color dangerRed;

  // ── 文字 ─────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;

  // ── 卡牌 ─────────────────────────────────────────
  /// 卡牌渐变起始色
  final Color cardBg1;

  /// 卡牌渐变结束色
  final Color cardBg2;

  /// 红色花色边框（♥♦ / 大王）
  final Color cardBorderRed;

  /// 黑色花色边框（♠♣ / 小王）
  final Color cardBorderBlack;

  /// 大王金色边框
  final Color cardBorderGold;

  /// 选中发光色
  final Color cardSelectedGlow;

  // ── 卡牌背面 ─────────────────────────────────────
  final Color cardBackBg;

  // ── 渐变 ─────────────────────────────────────────
  final LinearGradient tableGradient;
  final LinearGradient lanCardGradient;

  // ── 状态语义色 ───────────────────────────────────
  final Color statusInfoColor;
  final Color statusInfoBg;
  final Color statusErrorBg;
  final Color statusSuccessBg;
  final Color accentAmberBg;
  final Color teamColor;
  final Color overlay;
  final Color progressTrackBg;

  // ── 深色主题实例 ─────────────────────────────────
  static const GameColors dark = GameColors(
    bgBase: Color(0xFF0F0F0F),
    bgSurface: Color(0xFF1C1C1E),
    bgTable: Color(0xFF1A2A1A),
    primaryGreen: Color(0xFF4ADE80),
    accentAmber: Color(0xFFFBBF24),
    dangerRed: Color(0xFFF87171),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFA1A1AA),
    cardBg1: Color(0xFF1E1E2A),
    cardBg2: Color(0xFF2A2A3A),
    cardBorderRed: Color(0xFFF87171),
    cardBorderBlack: Color(0xFF94A3B8),
    cardBorderGold: Color(0xFFFBBF24),
    cardSelectedGlow: Color(0xFF4ADE80),
    cardBackBg: Color(0xFF1A1A2E),
    tableGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A2A1A), Color(0xFF0F1A0F)],
    ),
    lanCardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A2A1A), Color(0xFF0D1F2D)],
    ),
    statusInfoColor: Color(0xFF60A5FA),
    statusInfoBg: Color(0xFF1E3A5F),
    statusErrorBg: Color(0xFF3F1515),
    statusSuccessBg: Color(0xFF14301A),
    accentAmberBg: Color(0xFF3D2E05),
    teamColor: Color(0xFF3B82F6),
    overlay: Color(0x61000000),
    progressTrackBg: Color(0xFF3A3A3A),
  );

  // ── 浅色主题实例 ─────────────────────────────────
  static const GameColors light = GameColors(
    bgBase: Color(0xFFF5F5F5),
    bgSurface: Color(0xFFFFFFFF),
    bgTable: Color(0xFF2D5016),
    primaryGreen: Color(0xFF16A34A),
    accentAmber: Color(0xFFD97706),
    dangerRed: Color(0xFFDC2626),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    cardBg1: Color(0xFFFFFFFF),
    cardBg2: Color(0xFFF9FAFB),
    cardBorderRed: Color(0xFFEF4444),
    cardBorderBlack: Color(0xFF374151),
    cardBorderGold: Color(0xFFF59E0B),
    cardSelectedGlow: Color(0xFF16A34A),
    cardBackBg: Color(0xFF1E40AF),
    tableGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2D5016), Color(0xFF1A3A09)],
    ),
    lanCardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF15803D), Color(0xFF1E40AF)],
    ),
    statusInfoColor: Color(0xFF1D4ED8),
    statusInfoBg: Color(0xFFDBEAFE),
    statusErrorBg: Color(0xFFFEE2E2),
    statusSuccessBg: Color(0xFFDCFCE7),
    accentAmberBg: Color(0xFFFEF3C7),
    teamColor: Color(0xFF2563EB),
    overlay: Color(0x14000000),
    progressTrackBg: Color(0xFFE0E0E0),
  );

  @override
  GameColors copyWith({
    Color? bgBase,
    Color? bgSurface,
    Color? bgTable,
    Color? primaryGreen,
    Color? accentAmber,
    Color? dangerRed,
    Color? textPrimary,
    Color? textSecondary,
    Color? cardBg1,
    Color? cardBg2,
    Color? cardBorderRed,
    Color? cardBorderBlack,
    Color? cardBorderGold,
    Color? cardSelectedGlow,
    Color? cardBackBg,
    LinearGradient? tableGradient,
    LinearGradient? lanCardGradient,
    Color? statusInfoColor,
    Color? statusInfoBg,
    Color? statusErrorBg,
    Color? statusSuccessBg,
    Color? accentAmberBg,
    Color? teamColor,
    Color? overlay,
    Color? progressTrackBg,
  }) {
    return GameColors(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      bgTable: bgTable ?? this.bgTable,
      primaryGreen: primaryGreen ?? this.primaryGreen,
      accentAmber: accentAmber ?? this.accentAmber,
      dangerRed: dangerRed ?? this.dangerRed,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      cardBg1: cardBg1 ?? this.cardBg1,
      cardBg2: cardBg2 ?? this.cardBg2,
      cardBorderRed: cardBorderRed ?? this.cardBorderRed,
      cardBorderBlack: cardBorderBlack ?? this.cardBorderBlack,
      cardBorderGold: cardBorderGold ?? this.cardBorderGold,
      cardSelectedGlow: cardSelectedGlow ?? this.cardSelectedGlow,
      cardBackBg: cardBackBg ?? this.cardBackBg,
      tableGradient: tableGradient ?? this.tableGradient,
      lanCardGradient: lanCardGradient ?? this.lanCardGradient,
      statusInfoColor: statusInfoColor ?? this.statusInfoColor,
      statusInfoBg: statusInfoBg ?? this.statusInfoBg,
      statusErrorBg: statusErrorBg ?? this.statusErrorBg,
      statusSuccessBg: statusSuccessBg ?? this.statusSuccessBg,
      accentAmberBg: accentAmberBg ?? this.accentAmberBg,
      teamColor: teamColor ?? this.teamColor,
      overlay: overlay ?? this.overlay,
      progressTrackBg: progressTrackBg ?? this.progressTrackBg,
    );
  }

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    return GameColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgTable: Color.lerp(bgTable, other.bgTable, t)!,
      primaryGreen: Color.lerp(primaryGreen, other.primaryGreen, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      dangerRed: Color.lerp(dangerRed, other.dangerRed, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardBg1: Color.lerp(cardBg1, other.cardBg1, t)!,
      cardBg2: Color.lerp(cardBg2, other.cardBg2, t)!,
      cardBorderRed: Color.lerp(cardBorderRed, other.cardBorderRed, t)!,
      cardBorderBlack: Color.lerp(cardBorderBlack, other.cardBorderBlack, t)!,
      cardBorderGold: Color.lerp(cardBorderGold, other.cardBorderGold, t)!,
      cardSelectedGlow:
          Color.lerp(cardSelectedGlow, other.cardSelectedGlow, t)!,
      cardBackBg: Color.lerp(cardBackBg, other.cardBackBg, t)!,
      tableGradient: t < 0.5 ? tableGradient : other.tableGradient,
      lanCardGradient: t < 0.5 ? lanCardGradient : other.lanCardGradient,
      statusInfoColor: Color.lerp(statusInfoColor, other.statusInfoColor, t)!,
      statusInfoBg: Color.lerp(statusInfoBg, other.statusInfoBg, t)!,
      statusErrorBg: Color.lerp(statusErrorBg, other.statusErrorBg, t)!,
      statusSuccessBg: Color.lerp(statusSuccessBg, other.statusSuccessBg, t)!,
      accentAmberBg: Color.lerp(accentAmberBg, other.accentAmberBg, t)!,
      teamColor: Color.lerp(teamColor, other.teamColor, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      progressTrackBg: Color.lerp(progressTrackBg, other.progressTrackBg, t)!,
    );
  }
}

extension GameColorsContext on BuildContext {
  GameColors get gameColors =>
      Theme.of(this).extension<GameColors>() ?? GameColors.dark;
}
