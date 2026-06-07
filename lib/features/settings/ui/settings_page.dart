import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../database/database.dart';
import '../../../database/repositories/database_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _apiKeyMasked;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await AppConfig.getApiKey();
    setState(() {
      _apiKeyMasked = key != null
          ? '${key.substring(0, 8)}${'*' * (key.length - 8)}'
          : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // API Configuration
                _SectionHeader(title: 'AI 配置'),
                _SettingsTile(
                  icon: Icons.key,
                  title: 'Claude API Key',
                  subtitle: _apiKeyMasked ?? '未设置',
                  trailing: _apiKeyMasked != null
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20)
                      : const Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
                  onTap: () => _showApiKeyDialog(),
                ),
                _SettingsTile(
                  icon: Icons.smart_toy,
                  title: 'AI 模型',
                  subtitle: AppConfig.claudeModel,
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.tune,
                  title: '系统提示词',
                  subtitle: '自定义 AI 的行为和个性',
                  onTap: () => _showSystemPromptDialog(),
                ),
                const Divider(),

                // Tools
                _SectionHeader(title: '工具管理'),
                _SettingsTile(
                  icon: Icons.cloud,
                  title: '天气查询',
                  subtitle: '已启用',
                  trailing: const Icon(Icons.check, color: AppTheme.primaryGreen),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.checklist,
                  title: '待办事项',
                  subtitle: '已启用',
                  trailing: const Icon(Icons.check, color: AppTheme.primaryGreen),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.calendar_month,
                  title: '日历日程',
                  subtitle: '已启用',
                  trailing: const Icon(Icons.check, color: AppTheme.primaryGreen),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.notifications,
                  title: '提醒通知',
                  subtitle: '已启用',
                  trailing: const Icon(Icons.check, color: AppTheme.primaryGreen),
                  onTap: () {},
                ),
                const Divider(),

                // Memory
                _SectionHeader(title: '记忆管理'),
                _SettingsTile(
                  icon: Icons.memory,
                  title: 'AI 记忆',
                  subtitle: 'Aura 会记住你的偏好和习惯',
                  trailing: Switch(
                    value: true,
                    onChanged: (v) {},
                    activeColor: AppTheme.primaryGreen,
                  ),
                  onTap: () {},
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final memoriesAsync = ref.watch(allMemoriesProvider);
                    return memoriesAsync.when(
                      data: (memories) {
                        if (memories.isEmpty) return const SizedBox.shrink();
                        return ExpansionTile(
                          leading: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                          title: Text('已记录 ${memories.length} 条记忆'),
                          children: memories.map((m) => ListTile(
                            title: Text(m.key, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(m.value, style: const TextStyle(fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () async {
                                final db = ref.read(auraDatabaseProvider);
                                await db.deleteMemory(m.key);
                                ref.invalidate(allMemoriesProvider);
                              },
                            ),
                          )).toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                const Divider(),

                // Data Management
                _SectionHeader(title: '数据管理'),
                _SettingsTile(
                  icon: Icons.delete_sweep,
                  title: '清除所有对话',
                  subtitle: '删除所有聊天记录',
                  onTap: () => _showClearDataDialog(),
                  titleColor: AppTheme.dangerColor,
                ),
                _SettingsTile(
                  icon: Icons.delete_forever,
                  title: '清除所有数据',
                  subtitle: '包括记忆和设置',
                  onTap: () => _showClearAllDialog(),
                  titleColor: AppTheme.dangerColor,
                ),
                const Divider(),

                // About
                _SectionHeader(title: '关于'),
                const _SettingsTile(
                  icon: Icons.info,
                  title: '版本',
                  subtitle: 'v1.0.0',
                ),
                const _SettingsTile(
                  icon: Icons.code,
                  title: '技术栈',
                  subtitle: 'Flutter + Claude API',
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Claude API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('输入你的 Anthropic API Key。\n可以在 console.anthropic.com 获取。'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          if (_apiKeyMasked != null)
            TextButton(
              onPressed: () async {
                await AppConfig.deleteApiKey();
                setState(() => _apiKeyMasked = null);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('清除', style: TextStyle(color: AppTheme.dangerColor)),
            ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await AppConfig.saveApiKey(controller.text);
                await _loadApiKey();
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showSystemPromptDialog() {
    final controller = TextEditingController(text: AppConfig.defaultSystemPrompt);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('系统提示词'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 12,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有对话'),
        content: const Text('确定要删除所有聊天记录吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Clear conversations logic
              ref.invalidate(allConversationsProvider);
            },
            child: const Text('删除', style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('确定要删除所有数据吗？包括聊天记录、记忆和设置。此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AppConfig.deleteApiKey();
              setState(() => _apiKeyMasked = null);
            },
            child: const Text('删除所有', style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: titleColor ?? AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}