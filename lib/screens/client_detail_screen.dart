import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/formatting.dart';
import '../models/client_details.dart';
import '../state/client_list_notifier.dart';
import '../state/detail_notifier.dart';
import '../state/lookup_notifier.dart';
import '../widgets/detail_view.dart';
import '../widgets/list_toolbar.dart';

/// Карточка клиента: /clients/:id. Показывает и его автомобили —
/// связь «один ко многим» со стороны владельца.
class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key, required this.id});

  final int id;

  void _back(BuildContext context) =>
      context.go(context.read<ClientListNotifier>().query.toLocation());

  Future<void> _act(
    BuildContext context,
    Future<void> Function(int id) action,
    String done,
  ) async {
    final detail = context.read<DetailNotifier<ClientDetails>>();
    final lookup = context.read<LookupNotifier>();
    try {
      await action(id);
      if (!context.mounted) return;
      showMessage(context, done);
      lookup.load();
      await detail.load();
    } catch (e) {
      if (context.mounted) showMessage(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<DetailNotifier<ClientDetails>>();
    final lookup = context.watch<LookupNotifier>();
    final list = context.read<ClientListNotifier>();

    return Title(
      title: 'Клиент — Автосервис',
      color: Theme.of(context).colorScheme.primary,
      child: DetailStateView<ClientDetails>(
        state: detail.state,
        onRetry: detail.load,
        onBack: () => _back(context),
        notFoundText: 'Клиент №$id не найден',
        builder: (details) {
          final theme = Theme.of(context);
          final c = details.client;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => _back(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('К списку клиентов'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(c.fullName, style: theme.textTheme.headlineMedium),
                    if (c.isDeleted) const DeletedBadge(),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        InfoTile(
                          label: 'Телефон',
                          value: SelectableText(c.phone),
                        ),
                        InfoTile(
                          label: 'E-mail',
                          value: SelectableText(c.email),
                        ),
                        InfoTile(
                          label: 'Персональная скидка',
                          value: Text(
                            c.discount == 0 ? 'нет' : '${c.discount} %',
                          ),
                        ),
                        InfoTile(
                          label: 'Клиент с',
                          value: Text(formatDate(c.registeredAt)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Автомобили (${details.cars.length})',
                      style: theme.textTheme.titleLarge,
                    ),
                    if (details.cars.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => context.go('/cars?clientId=${c.id}'),
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Открыть в списке автомобилей'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (details.cars.isEmpty)
                  Text(
                    'За клиентом не числится ни одного автомобиля.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (final car in details.cars)
                          ListTile(
                            leading: const Icon(Icons.directions_car_outlined),
                            title: Text(
                              '${car.plate} · ${lookup.brandName(car.brandId)} '
                              '${car.model}',
                            ),
                            subtitle: Text(
                              '${car.year} г. · ${formatMileage(car.mileage)}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go('/cars/${car.id}'),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: c.isDeleted
                      ? [
                          FilledButton.icon(
                            onPressed: () => _act(
                              context,
                              list.restore,
                              'Клиент восстановлен',
                            ),
                            icon: const Icon(Icons.restore_from_trash),
                            label: const Text('Восстановить'),
                          ),
                        ]
                      : [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _act(context, list.softDelete, 'Клиент удалён'),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Удалить'),
                          ),
                        ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
