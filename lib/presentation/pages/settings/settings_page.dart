import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poke_game/presentation/pages/settings/settings_provider.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 个人信息
          _buildSectionHeader(context, '个人信息'),
          _buildPersonalInfoSection(context, ref, settings),

          const Divider(height: 32),

          // 游戏设置
          _buildSectionHeader(context, '游戏设置'),
          _buildGameSettingsSection(context, ref, settings),

          const Divider(height: 32),

          // 显示设置
          _buildSectionHeader(context, '显示设置'),
          _buildDisplaySettingsSection(context, ref, settings),

          const Divider(height: 32),

          // 关于
          _buildSectionHeader(context, '关于'),
          _buildAboutSection(context),

          const SizedBox(height: 32),

          // 重置按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => _showResetDialog(context, ref),
              child: const Text('重置所有设置'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  // ==================== 个人信息 ====================

  Widget _buildPersonalInfoSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return Column(
      children: [
        // 头像
        ListTile(
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: _getAvatarColor(settings.avatarIndex),
            child: Text(
              settings.playerName.isNotEmpty
                  ? settings.playerName[0].toUpperCase()
                  : 'P',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          title: const Text('头像'),
          subtitle: Text('点击更换颜色'),
          onTap: () => _showAvatarPicker(context, ref, settings.avatarIndex),
        ),

        // 昵称
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('昵称'),
          subtitle: Text(settings.playerName),
          onTap: () => _showNameDialog(context, ref, settings.playerName),
        ),
      ],
    );
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref, int currentIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择头像颜色',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(10, (index) {
                  final isSelected = index == currentIndex;
                  return GestureDetector(
                    onTap: () {
                      ref.read(settingsProvider.notifier).setAvatarIndex(index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getAvatarColor(index),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改昵称'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 12,
            decoration: const InputDecoration(
              hintText: '请输入昵称',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref.read(settingsProvider.notifier).setPlayerName(name);
                }
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  // ==================== 游戏设置 ====================

  Widget _buildGameSettingsSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.volume_up_outlined),
          title: const Text('音效'),
          subtitle: const Text('游戏音效开关'),
          value: settings.soundEnabled,
          onChanged: (_) => ref.read(settingsProvider.notifier).toggleSound(),
        ),

        SwitchListTile(
          secondary: const Icon(Icons.music_note_outlined),
          title: const Text('背景音乐'),
          subtitle: const Text('游戏背景音乐开关'),
          value: settings.musicEnabled,
          onChanged: (_) => ref.read(settingsProvider.notifier).toggleMusic(),
        ),

        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: const Text('振动反馈'),
          subtitle: const Text('操作时的振动反馈'),
          value: settings.vibrationEnabled,
          onChanged: (_) {
            ref.read(settingsProvider.notifier).toggleVibration();
            // 触发一次振动作为反馈
            if (!settings.vibrationEnabled) {
              HapticFeedback.mediumImpact();
            }
          },
        ),
      ],
    );
  }

  // ==================== 显示设置 ====================

  Widget _buildDisplaySettingsSection(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('主题模式'),
          subtitle: Text(_getThemeModeName(settings.themeMode)),
          onTap: () => _showThemeModePicker(context, ref, settings.themeMode),
        ),

        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('语言'),
          subtitle: Text(_getLanguageName(settings.languageCode)),
          onTap: () => _showLanguagePicker(context, ref, settings.languageCode),
        ),
      ],
    );
  }

  void _showThemeModePicker(BuildContext context, WidgetRef ref, ThemeModeSetting currentMode) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择主题模式',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...ThemeModeSetting.values.map((mode) {
                final isSelected = mode == currentMode;
                return ListTile(
                  leading: Icon(_getThemeModeIcon(mode)),
                  title: Text(_getThemeModeName(mode)),
                  trailing: isSelected
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  IconData _getThemeModeIcon(ThemeModeSetting mode) {
    switch (mode) {
      case ThemeModeSetting.system:
        return Icons.brightness_auto;
      case ThemeModeSetting.light:
        return Icons.light_mode;
      case ThemeModeSetting.dark:
        return Icons.dark_mode;
    }
  }

  String _getThemeModeName(ThemeModeSetting mode) {
    switch (mode) {
      case ThemeModeSetting.system:
        return '跟随系统';
      case ThemeModeSetting.light:
        return '浅色模式';
      case ThemeModeSetting.dark:
        return '深色模式';
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentCode) {
    final languages = [
      {'code': 'zh', 'name': '简体中文'},
      {'code': 'en', 'name': 'English'},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择语言',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...languages.map((lang) {
                final isSelected = lang['code'] == currentCode;
                return ListTile(
                  title: Text(lang['name']!),
                  trailing: isSelected
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage(lang['code']!);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'zh':
        return '简体中文';
      case 'en':
        return 'English';
      default:
        return '简体中文';
    }
  }

  // ==================== 关于 ====================

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('版本信息'),
          subtitle: const Text('v1.0.0'),
        ),

        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('开发者'),
          subtitle: const Text('Poke Game Team'),
        ),

        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('用户协议'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAgreementDialog(context, '用户协议', _userAgreement),
        ),

        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('隐私政策'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAgreementDialog(context, '隐私政策', _privacyPolicy),
        ),

        ListTile(
          leading: const Icon(Icons.favorite_outline),
          title: const Text('给个好评'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('感谢您的支持！'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAgreementDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置设置'),
          content: const Text('确定要重置所有设置为默认值吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).resetSettings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('设置已重置'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  static const String _userAgreement = '''
一、服务条款
欢迎使用扑克游戏合集。使用本应用即表示您同意遵守以下条款。

二、用户行为规范
1. 请勿使用外挂或作弊软件
2. 请勿进行任何破坏游戏公平性的行为
3. 请勿发布违法、违规内容

三、知识产权
本应用的所有内容均受知识产权法保护。

四、免责声明
本应用仅供娱乐，请合理安排游戏时间。
''';

  static const String _privacyPolicy = '''
一、信息收集
我们可能收集以下信息：
- 设备信息
- 游戏记录
- 设置偏好

二、信息使用
收集的信息用于：
- 提供更好的游戏体验
- 改进产品功能
- 数据统计分析

三、信息保护
我们承诺保护您的个人信息安全。

四、联系方式
如有疑问，请联系客服。
''';
}
