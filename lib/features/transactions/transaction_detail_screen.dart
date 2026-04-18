import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart';

final transactionDetailProvider =
    FutureProvider.autoDispose.family<TransactionModel, String>((ref, id) {
  return TransactionRepository().getById(id);
});

// ─────────────────────────────────────────────────────────────────────────────
class TransactionDetailScreen extends ConsumerWidget {
  final String id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionDetailProvider(id));

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          if (async.value != null)
            PopupMenuButton<String>(
              color: FinaColors.surface2,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'edit') {
                  context.push('/transactions/edit/$id');
                } else if (v == 'delete') {
                  _confirmDelete(context, ref, async.value!);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus', style: TextStyle(color: FinaColors.red)),
                ),
              ],
            ),
        ],
      ),
      body: async.when(
        data: (tx) => _buildBody(context, ref, tx),
        loading: () => const Center(
            child: CircularProgressIndicator(color: FinaColors.copper)),
        error: (e, _) => FinaErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(transactionDetailProvider(id)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TransactionModel tx) {
    final (typeLabel, typeColor, typeIcon) = switch (tx.type) {
      'income' => ('Pemasukan', FinaColors.green, '📥'),
      'expense' => ('Pengeluaran', FinaColors.red, '📤'),
      _ => ('Transfer', FinaColors.blue, '🔄'),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // ── Amount hero ────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: FinaColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FinaColors.border),
          ),
          child: Column(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: tx.isIncome
                    ? FinaColors.icGreen
                    : tx.isTransfer
                        ? FinaColors.icBlue
                        : FinaColors.icRed,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(tx.category?.icon ?? typeIcon,
                  style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 16),
            Text(
              '${tx.isIncome ? '+' : tx.isExpense ? '-' : ''}${formatCurrency(tx.amount)}',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                  letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            FinaPill(
              typeLabel,
              variant: tx.isIncome
                  ? PillVariant.green
                  : tx.isTransfer
                      ? PillVariant.blue
                      : PillVariant.red,
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Details ────────────────────────────────────────────────────────
        FinaCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Kategori',
              value: tx.category?.name ?? '-',
            ),
            const FinaDivider(indent: 56),
            _DetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Rekening',
              value: tx.account?.name ?? '-',
            ),
            const FinaDivider(indent: 56),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              value: formatDate(tx.date, pattern: 'EEEE, d MMMM yyyy'),
            ),
            if (tx.note != null && tx.note!.isNotEmpty) ...[
              const FinaDivider(indent: 56),
              _DetailRow(
                icon: Icons.notes_rounded,
                label: 'Catatan',
                value: tx.note!,
              ),
            ],
            if (tx.tags.isNotEmpty) ...[
              const FinaDivider(indent: 56),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: FinaColors.surface2,
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.label_outline_rounded,
                        size: 18, color: FinaColors.text2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tags',
                          style:
                              TextStyle(fontSize: 11, color: FinaColors.text2)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: tx.tags
                            .map((t) => FinaPill(t, variant: PillVariant.blue))
                            .toList(),
                      ),
                    ],
                  )),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 20),

        // ── Foto Struk ─────────────────────────────────────────────────────
        if (tx.imageUrl != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('FOTO STRUK',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 2, color: FinaColors.copper)),
            ),
          ),
          GestureDetector(
            onTap: () => _showFullImage(context, tx.imageUrl!),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    tx.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                            color: FinaColors.surface2,
                            borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: FinaColors.copper,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                          color: FinaColors.surface2,
                          borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: FinaColors.text2, size: 36),
                          SizedBox(height: 8),
                          Text('Gambar tidak bisa dimuat',
                              style: TextStyle(
                                  color: FinaColors.text2, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Tap to fullscreen hint
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.fullscreen_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Perbesar',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── ID ─────────────────────────────────────────────────────────────
        FinaCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.fingerprint_rounded,
                size: 16, color: FinaColors.text2),
            const SizedBox(width: 8),
            Expanded(
                child: Text(tx.id,
                    style: const TextStyle(
                        fontSize: 10,
                        color: FinaColors.text2,
                        fontFamily: 'monospace'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('Foto Struk',
                  style: TextStyle(color: Colors.white)),
            ),
            body: Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64)),
              ),
            ),
          ),
        ));
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TransactionModel tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FinaColors.surface,
        title: const Text('Hapus Transaksi?'),
        content: Text(
            '${tx.category?.name ?? tx.type} — ${formatCurrency(tx.amount)} akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Hapus', style: TextStyle(color: FinaColors.red))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await TransactionRepository().delete(tx.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Transaksi dihapus')));
          context.pop();
        }
      } on ApiException catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: FinaColors.surface2,
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: FinaColors.text2),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: FinaColors.text2)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          )),
        ]),
      );
}
