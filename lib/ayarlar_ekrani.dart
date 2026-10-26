import 'package:flutter/material.dart';

import 'navigasyon.dart';
import 'tema.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final appearance = AppThemeScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Ayarlar'),
        actions: const [NotificationMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Görünüm', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Uygulama temasını ve uyumlu vurgu rengini seç.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<AppTheme>(
                    segments: const [
                      ButtonSegment(
                        value: AppTheme.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Koyu'),
                      ),
                      ButtonSegment(
                        value: AppTheme.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Açık'),
                      ),
                    ],
                    selected: {appearance.selectedTheme},
                    onSelectionChanged: (selection) =>
                        appearance.onThemeChanged(selection.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vurgu rengi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seçilen renk düğmeler ve simgelerde kullanılır.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppAccent.values.map((accent) {
                      final selected = appearance.selectedAccent == accent;
                      return ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: accent.color,
                          radius: 9,
                        ),
                        label: Text(accent.label),
                        selected: selected,
                        onSelected: (_) => appearance.onAccentChanged(accent),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: Icon(Icons.palette_outlined, color: scheme.primary),
              title: const Text('Renk uyumu'),
              subtitle: const Text(
                'Renkler açık ve koyu temalarda okunaklı olacak şekilde '
                'uyarlanır.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
