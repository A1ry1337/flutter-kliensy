import 'package:flutter/material.dart';
import 'package:kliensy/features/auth/state/auth_controller.dart';
import 'package:kliensy/shared/ui/app_shell.dart';
import 'package:kliensy/shared/ui/page_header.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
          PageHeader(
            title: 'Настройки',
            breadcrumbs: [
              Breadcrumb(label: 'Настройки', onTap: null),
            ],
          )
        else
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: const Text(
              'Настройки',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D2E),
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsSection(
                  title: 'Профиль',
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Личные данные',
                      subtitle: 'Имя, email, телефон',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Безопасность',
                      subtitle: 'Пароль и сессии',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsSection(
                  title: 'Уведомления',
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Push-уведомления',
                      subtitle: 'Новые заявки и изменения',
                      onTap: () {},
                      trailing: Switch(
                        value: true,
                        onChanged: (_) {},
                        activeColor: const Color(0xFF1A5BFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsSection(
                  title: 'Приложение',
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'О приложении',
                      subtitle: 'Версия 1.0.0',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Выйти',
                      subtitle: 'Завершить текущую сессию',
                      titleColor: Colors.red,
                      onTap: () => authController.logout(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    const Divider(
                        height: 1,
                        indent: 52,
                        color: Color(0xFFF5F5F5)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: titleColor == null
                    ? const Color(0xFFF4F6FB)
                    : Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: titleColor ?? const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? const Color(0xFF1A1D2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}