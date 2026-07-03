import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/interactive_card.dart';
import '../../../shared/widgets/load_more_list_view.dart';
import '../data/notifications_repository.dart';
import '../models/notification_models.dart';
import '../providers/notifications_providers.dart';

class NotificationsTab extends ConsumerStatefulWidget {
  const NotificationsTab({super.key});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
  var _listKey = 0;

  Future<({List<AppNotificationModel> items, int lastPage})> _loadPage(
    int page,
  ) async {
    final result =
        await ref.read(notificationsRepositoryProvider).list(page: page);
    return (items: result.items, lastPage: result.meta.lastPage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await ref
                    .read(notificationsRepositoryProvider)
                    .markAllRead();
                setState(() => _listKey++);
                ref.invalidate(unreadNotificationsProvider);
              },
              icon: const Icon(Icons.done_all),
              label: const Text('Tandai semua dibaca'),
            ),
          ),
        ),
        Expanded(
          child: LoadMoreListView<AppNotificationModel>(
            key: ValueKey('notifications-$_listKey'),
            loader: _loadPage,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            onRefreshExtra: () async {
              ref.invalidate(unreadNotificationsProvider);
            },
            empty: const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'Belum ada notifikasi',
              subtitle: 'Notifikasi sistem dan transaksi akan tampil di sini',
            ),
            itemBuilder: (context, n, index) {
              return InteractiveCard(
                margin: EdgeInsets.zero,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (!n.isRead) {
                    await ref
                        .read(notificationsRepositoryProvider)
                        .markRead(n.id);
                    setState(() => _listKey++);
                    ref.invalidate(unreadNotificationsProvider);
                  }
                },
                child: ListTile(
                  leading: Icon(
                    n.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: n.isRead
                        ? null
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight:
                          n.isRead ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(n.body),
                  trailing: Text(
                    n.createdAt?.substring(0, 16) ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}