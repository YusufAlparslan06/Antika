import 'package:flutter/material.dart';

import 'modeller.dart';
import 'navigasyon.dart';

class UserRolesPage extends StatefulWidget {
  const UserRolesPage({
    super.key,
    required this.users,
    required this.currentUserId,
    required this.isLoading,
    required this.error,
    required this.onBack,
    required this.onRefresh,
    required this.onChangeRole,
  });

  final List<AppUser> users;
  final String? currentUserId;
  final bool isLoading;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AppUser, String) onChangeRole;

  @override
  State<UserRolesPage> createState() => _UserRolesPageState();
}

class _UserRolesPageState extends State<UserRolesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Kullanıcı Rolleri'),
        actions: [
          IconButton(
            tooltip: 'Listeyi yenile',
            onPressed: widget.isLoading ? null : widget.onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          const NotificationMenuButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kayıtlı kullanıcılar',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Yöneticiler kullanıcı rollerini ve tüm kayıtları yönetebilir. '
              'Personel ürün ekleyip düzenleyebilir ve satış kaydedebilir; '
              'kayıt silemez veya kullanıcı rolleri atayamaz.',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.error != null
                  ? Center(
                      child: SelectableText(
                        'Kullanıcılar yüklenemedi: ${widget.error}',
                      ),
                    )
                  : widget.users.isEmpty
                  ? const Center(child: Text('Kayıtlı kullanıcı bulunamadı.'))
                  : Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        itemCount: widget.users.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = widget.users[index];
                          final isCurrentUser = user.id == widget.currentUserId;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                user.role == 'yonetici'
                                    ? Icons.admin_panel_settings_outlined
                                    : Icons.person_outline,
                              ),
                            ),
                            title: Text(
                              user.fullName.isEmpty
                                  ? user.email
                                  : user.fullName,
                            ),
                            subtitle: Text(
                              isCurrentUser
                                  ? '${user.email} • Senin hesabın'
                                  : user.email,
                            ),
                            trailing: SizedBox(
                              width: 160,
                              child: DropdownButtonFormField<String>(
                                initialValue: user.role,
                                decoration: const InputDecoration(
                                  labelText: 'Rol',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'personel',
                                    child: Text('Personel'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'yonetici',
                                    child: Text('Yönetici'),
                                  ),
                                ],
                                onChanged: isCurrentUser
                                    ? null
                                    : (role) {
                                        if (role != null && role != user.role) {
                                          widget.onChangeRole(user, role);
                                        }
                                      },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
