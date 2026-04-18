import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import 'package:finance_app_mobile/core/widgets/icon_circle.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart' hide IconCircle;

final _transferAccountsProvider =
    FutureProvider.autoDispose<List<AccountModel>>(
        (_) => AccountRepository().getAll());

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _State();
}

class _State extends ConsumerState<TransferScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  AccountModel? _from, _to;
  DateTime _date = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_from == null || _to == null) {
      setState(() => _error = 'Pilih rekening asal dan tujuan');
      return;
    }
    if (_from!.id == _to!.id) {
      setState(() => _error = 'Rekening asal dan tujuan harus berbeda');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Jumlah tidak valid');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await TransactionRepository().transfer(
        fromAccountId: _from!.id,
        toAccountId: _to!.id,
        amount: amount,
        date: DateFormat('yyyy-MM-dd').format(_date),
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Transfer berhasil ✅')));
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(_transferAccountsProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: const Text('Transfer Rekening'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            if (_error != null) ...[
              FinaCard(
                copper: true,
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style:
                        const TextStyle(color: FinaColors.red, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            // Transfer arrow card
            FinaCard(
              child: Column(children: [
                accounts.when(
                  data: (list) => _AccountSelector(
                    label: 'Dari Rekening',
                    account: _from,
                    onTap: () => _pickAccount(list, isFrom: true),
                  ),
                  loading: () => const FinaSkeletonBox(height: 60),
                  error: (_, __) => const SizedBox(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(child: FinaDivider()),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FinaColors.icBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.south_rounded,
                          color: FinaColors.blue, size: 16),
                    ),
                    Expanded(child: FinaDivider()),
                  ]),
                ),
                accounts.when(
                  data: (list) => _AccountSelector(
                    label: 'Ke Rekening',
                    account: _to,
                    onTap: () => _pickAccount(list, isFrom: false),
                  ),
                  loading: () => const FinaSkeletonBox(height: 60),
                  error: (_, __) => const SizedBox(),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Amount
            const _SectionLabel(label: 'Jumlah Transfer'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: FinaColors.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FinaColors.border),
              ),
              child: Row(children: [
                const Text('Rp',
                    style: TextStyle(
                        color: FinaColors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: FinaColors.text),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0',
                      hintStyle:
                          TextStyle(color: FinaColors.muted, fontSize: 28),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Date
            const _SectionLabel(label: 'Tanggal'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: FinaColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FinaColors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: FinaColors.text2),
                  const SizedBox(width: 12),
                  Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date),
                      style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: FinaColors.text2, size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            const _SectionLabel(label: 'Catatan'),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: FinaColors.text),
              decoration:
                  const InputDecoration(hintText: 'Tambahkan catatan...'),
            ),

            const SizedBox(height: 32),
            FinaButton(
                label: 'Transfer Sekarang',
                onPressed: _submit,
                isLoading: _loading),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  void _pickAccount(List<AccountModel> list, {required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(isFrom ? 'Rekening Asal' : 'Rekening Tujuan',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const FinaDivider(),
          ...list.map((a) => ListTile(
                leading: IconCircle(
                  icon: a.icon ?? '📌',
                  bgColor: FinaColors.icCopper,
                ),
                title: Text(a.name,
                    style: const TextStyle(color: FinaColors.text)),
                subtitle: Text(formatCurrency(a.balance),
                    style:
                        const TextStyle(color: FinaColors.blue, fontSize: 12)),
                onTap: () {
                  setState(() => isFrom ? _from = a : _to = a);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(primary: FinaColors.copper)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }
}

class _AccountSelector extends StatelessWidget {
  final String label;
  final AccountModel? account;
  final VoidCallback onTap;
  const _AccountSelector(
      {required this.label, this.account, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Row(children: [
          IconCircle(
            icon: account?.icon ?? '💳',
            bgColor: FinaColors.icBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: FinaColors.text2)),
              Text(
                account?.name ?? 'Pilih rekening...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: account != null ? FinaColors.text : FinaColors.muted,
                ),
              ),
              if (account != null)
                Text(formatCurrency(account!.balance),
                    style:
                        const TextStyle(fontSize: 11, color: FinaColors.blue)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: FinaColors.text2),
        ]),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: FinaColors.text2,
              )),
        ),
      );
}
