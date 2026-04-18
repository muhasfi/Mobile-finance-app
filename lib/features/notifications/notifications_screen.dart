import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart';

final notificationsProvider =
    FutureProvider.autoDispose<PaginatedResponse<NotificationModel>>(
  (_) => NotificationRepository().getAll());

// ─────────────────────────────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationRepository().markAllAsRead();
              ref.refresh(notificationsProvider);
            },
            child: const Text('Baca semua',
              style: TextStyle(color: FinaColors.copper, fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              await NotificationRepository().deleteAll();
              ref.refresh(notificationsProvider);
            },
            child: const Text('Hapus semua',
              style: TextStyle(color: FinaColors.red, fontSize: 12)),
          ),
        ],
      ),
      body: async.when(
        data: (page) => page.data.isEmpty
            ? const FinaEmptyState(
                emoji: '🔔',
                title: 'Tidak ada notifikasi',
                subtitle: 'Kamu sudah membaca semua notifikasi',
              )
            : RefreshIndicator(
                color: FinaColors.copper,
                backgroundColor: FinaColors.surface,
                onRefresh: () => ref.refresh(notificationsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: page.data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _NotifTile(
                    notif: page.data[i],
                    onRead: () async {
                      await NotificationRepository().markAsRead(page.data[i].id);
                      ref.refresh(notificationsProvider);
                    },
                    onDelete: () async {
                      await NotificationRepository().delete(page.data[i].id);
                      ref.refresh(notificationsProvider);
                    },
                  ),
                ),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: FinaColors.copper)),
        error: (e, _) => FinaErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(notificationsProvider),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onRead, onDelete;
  const _NotifTile({required this.notif, required this.onRead, required this.onDelete});

  String get _icon {
    final type = notif.type.toLowerCase();
    if (type.contains('budget')) return '🎯';
    if (type.contains('recurring')) return '🔄';
    if (type.contains('transaction')) return '💳';
    return '🔔';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Color(0x33E05C5C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: FinaColors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: notif.isUnread ? onRead : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isUnread
                ? FinaColors.surface.withBlue(32)
                : FinaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isUnread
                  ? Color(0x4DC8783A)
                  : FinaColors.border,
            ),
          ),
          child: Row(children: [
            Stack(
              children: [
                IconCircle(emoji: _icon, bgColor: FinaColors.icCopper),
                if (notif.isUnread)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: FinaColors.copper, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(notif.title, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: notif.isUnread ? FinaColors.text : FinaColors.text2,
                )),
                const SizedBox(height: 2),
                Text(notif.message, style: const TextStyle(
                  fontSize: 12, color: FinaColors.text2),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(formatDate(notif.createdAt, pattern: 'd MMM yyyy, HH:mm'),
                  style: const TextStyle(fontSize: 10, color: FinaColors.muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
