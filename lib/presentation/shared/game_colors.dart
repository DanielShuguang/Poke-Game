// lib/presentation/shared/game_colors.dart
import 'package:flutter/material.dart';

class GameColors {
  GameColors._();

  // ── 背景层 ──────────────────────────────────────
  /// Scaffold 基础背景
  static const Color bgBase = Color(0xFF0F0F0F);

  /// 面板、信息卡片背景
  static const Color bgSurface = Color(0xFF1C1C1E);

  /// 游戏桌面背景（保留绿色感）
  static const Color bgTable = Color(0xFF1A2A1A);

  // ── 主色调 ──────────────────────────────────────
  /// 主操作按钮（出牌、确认）
  static const Color primaryGreen = Color(0xFF4ADE80);

  /// 强调色（庄家标记、积分高亮）
  static const Color accentAmber = Color(0xFFFBBF24);

  /// 危险/退出确认
  static const Color dangerRed = Color(0xFFF87171);

  // ── 文字 ─────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA1A1AA);

  // ── 卡牌 ─────────────────────────────────────────
  /// 卡牌渐变起始色
  static const Color cardBg1 = Color(0xFF1E1E2A);

  /// 卡牌渐变结束色
  static const Color cardBg2 = Color(0xFF2A2A3A);

  /// 红色花色边框（♥♦ / 大王）
  static const Color cardBorderRed = Color(0xFFF87171);

  /// 黑色花色边框（♠♣ / 小王）
  static const Color cardBorderBlack = Color(0xFF94A3B8);

  /// 大王金色边框
  static const Color cardBorderGold = Color(0xFFFBBF24);

  /// 选中发光色
  static const Color cardSelectedGlow = Color(0xFF4ADE80);

  // ── 卡牌背面 ─────────────────────────────────────
  static const Color cardBackBg = Color(0xFF1A1A2E);

  // ── 渐变 ─────────────────────────────────────────
  static const LinearGradient tableGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2A1A), Color(0xFF0F1A0F)],
  );

  static const LinearGradient lanCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2A1A), Color(0xFF0D1F2D)],
  );
}
