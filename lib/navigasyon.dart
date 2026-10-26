import 'package:flutter/material.dart';

class AdminNavigationScope extends InheritedWidget {
  const AdminNavigationScope({
    super.key,
    required this.onNavigate,
    required super.child,
  });

  final ValueChanged<AdminPage> onNavigate;

  static AdminNavigationScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminNavigationScope>()!;

  @override
  bool updateShouldNotify(AdminNavigationScope oldWidget) =>
      onNavigate != oldWidget.onNavigate;
}

class QuickAccessMenuItem extends StatelessWidget {
  const QuickAccessMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationMenuButton extends StatelessWidget {
  const NotificationMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = AdminNavigationScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mesajlar',
            onPressed: () => navigation.onNavigate(AdminPage.messages),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          Semantics(
            button: true,
            label: 'Hızlı erişim menüsü',
            child: InkWell(
              onTap: () async {
                final destination = await showGeneralDialog<AdminPage>(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Paneli kapat',
                  barrierColor: Colors.black.withValues(alpha: 0.24),
                  transitionDuration: const Duration(milliseconds: 220),
                  pageBuilder: (dialogContext, animation, secondaryAnimation) {
                    final dialogColorScheme = Theme.of(
                      dialogContext,
                    ).colorScheme;
                    final screenWidth = MediaQuery.sizeOf(dialogContext).width;

                    return SafeArea(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 68,
                            right: 12,
                            left: 12,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: SizedBox(
                              width: screenWidth - 24,
                              child: Material(
                                color: dialogColorScheme.surface,
                                elevation: 18,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.28,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  side: BorderSide(
                                    color: dialogColorScheme.outlineVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    16,
                                    18,
                                    18,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: dialogColorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              Icons
                                                  .notifications_active_rounded,
                                              color: dialogColorScheme.primary,
                                              size: 21,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hızlı erişim',
                                                  style: Theme.of(dialogContext)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Gitmek istediğin bölümü seç',
                                                  style: Theme.of(dialogContext)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: dialogColorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => Navigator.of(
                                              dialogContext,
                                            ).pop(),
                                            tooltip: 'Kapat',
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Divider(
                                        height: 1,
                                        color: dialogColorScheme.outlineVariant
                                            .withValues(alpha: 0.55),
                                      ),
                                      const SizedBox(height: 10),
                                      QuickAccessMenuItem(
                                        icon: Icons.swap_vert_circle_outlined,
                                        title: 'Stok Hareketleri',
                                        subtitle:
                                            'Stok giriş ve çıkış kayıtları',
                                        onTap: () => Navigator.of(
                                          dialogContext,
                                        ).pop(AdminPage.stockMovements),
                                      ),
                                      const SizedBox(height: 8),
                                      const SizedBox(height: 8),
                                      QuickAccessMenuItem(
                                        icon: Icons.settings_outlined,
                                        title: 'Ayarlar',
                                        subtitle: 'Görünüm ve renk tercihleri',
                                        onTap: () => Navigator.of(
                                          dialogContext,
                                        ).pop(AdminPage.settings),
                                      ),
                                      const SizedBox(height: 8),
                                      QuickAccessMenuItem(
                                        icon: Icons.fact_check_outlined,
                                        title: 'Envanter sayımı',
                                        subtitle:
                                            'Fiziksel stokları karşılaştır',
                                        onTap: () => Navigator.of(
                                          dialogContext,
                                        ).pop(AdminPage.inventoryCount),
                                      ),
                                      const SizedBox(height: 8),
                                      QuickAccessMenuItem(
                                        icon: Icons.history_outlined,
                                        title: 'İşlem geçmişi',
                                        subtitle:
                                            'Kullanıcı işlemlerini incele',
                                        onTap: () => Navigator.of(
                                          dialogContext,
                                        ).pop(AdminPage.activityHistory),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  transitionBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );
                        return FadeTransition(
                          opacity: curvedAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.08, 0),
                              end: Offset.zero,
                            ).animate(curvedAnimation),
                            child: child,
                          ),
                        );
                      },
                );
                if (destination != null && context.mounted) {
                  navigation.onNavigate(destination);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: colorScheme.onPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kısayollar',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more_rounded,
                      color: colorScheme.onPrimary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum AdminPage {
  menu,
  create,
  list,
  auction,
  createAuction,
  sales,
  createSale,
  reports,
  customers,
  stockMovements,
  users,
  settings,
  messages,
  inventoryCount,
  activityHistory,
  productTimeline,
  backupImport,
}
