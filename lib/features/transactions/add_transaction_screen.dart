import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import 'package:finance_app_mobile/core/widgets/icon_circle.dart';
import '../../core/widgets/shared_widgets.dart' hide IconCircle;

// ── Providers ─────────────────────────────────────────────────────────────────
final _addAccountsProvider = FutureProvider.autoDispose<List<AccountModel>>(
    (_) => AccountRepository().getAll());
final _addCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>(
    (_) => CategoryRepository().getAll());

// ─────────────────────────────────────────────────────────────────────────────
class AddTransactionScreen extends ConsumerStatefulWidget {
  final String initialType;
  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  ConsumerState<AddTransactionScreen> createState() => _State();
}

class _State extends ConsumerState<AddTransactionScreen> {
  late String _type;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  AccountModel? _account;
  CategoryModel? _category;
  DateTime _date = DateTime.now();
  File? _image; // gambar yang dipilih
  bool _loading = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ─────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Tambah Foto Struk',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const FinaDivider(),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: FinaColors.icBlue,
                    borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Icon(Icons.camera_alt_rounded,
                    color: FinaColors.blue, size: 20),
              ),
              title: const Text('Ambil Foto'),
              subtitle: const Text('Buka kamera langsung',
                  style: TextStyle(fontSize: 12, color: FinaColors.text2)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: FinaColors.icGreen,
                    borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Icon(Icons.photo_library_rounded,
                    color: FinaColors.green, size: 20),
              ),
              title: const Text('Pilih dari Galeri'),
              subtitle: const Text('Upload dari foto tersimpan',
                  style: TextStyle(fontSize: 12, color: FinaColors.text2)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_image != null)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: FinaColors.icRed,
                      borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: FinaColors.red, size: 20),
                ),
                title: const Text('Hapus Foto',
                    style: TextStyle(color: FinaColors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _image = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_account == null) {
      setState(() => _error = 'Pilih rekening terlebih dahulu');
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
      final data = {
        'account_id': _account!.id,
        if (_category != null) 'category_id': _category!.id,
        'type': _type,
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        if (_noteCtrl.text.isNotEmpty) 'note': _noteCtrl.text,
      };

      if (_image != null) {
        await TransactionRepository().createWithImage(data, _image!.path);
      } else {
        await TransactionRepository().create(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil ditambahkan ✅')));
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(_addAccountsProvider);
    final categories = ref.watch(_addCategoriesProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title:
            Text(_type == 'income' ? 'Tambah Pemasukan' : 'Tambah Pengeluaran'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // ── Type Switcher ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: FinaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FinaColors.border),
              ),
              child: Row(children: [
                _typeBtn('expense', '📤 Pengeluaran'),
                _typeBtn('income', '📥 Pemasukan'),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null) ...[
              FinaCard(
                copper: true,
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: FinaColors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: FinaColors.red, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // ── Amount ────────────────────────────────────────────────────
            _SectionLabel(label: 'Jumlah'),
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
                        color: FinaColors.copper2,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
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
            const SizedBox(height: 20),

            // ── Account ───────────────────────────────────────────────────
            _SectionLabel(label: 'Rekening'),
            accounts.when(
              data: (list) => _Picker(
                label: 'Pilih Rekening',
                value: _account?.name,
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => _showAccountPicker(list),
              ),
              loading: () => const FinaSkeletonBox(height: 52, radius: 12),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // ── Category ──────────────────────────────────────────────────
            _SectionLabel(label: 'Kategori'),
            categories.when(
              data: (list) {
                final filtered = list.where((c) => c.type == _type).toList();
                return _Picker(
                  label: 'Pilih Kategori (opsional)',
                  value: _category?.name,
                  icon: Icons.category_outlined,
                  onTap: () => _showCategoryPicker(filtered),
                );
              },
              loading: () => const FinaSkeletonBox(height: 52, radius: 12),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // ── Date ──────────────────────────────────────────────────────
            _SectionLabel(label: 'Tanggal'),
            _Picker(
              label: DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // ── Note ──────────────────────────────────────────────────────
            _SectionLabel(label: 'Catatan'),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: FinaColors.text),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tambahkan catatan...',
              ),
            ),
            const SizedBox(height: 20),

            // ── Foto Struk ────────────────────────────────────────────────
            _SectionLabel(label: 'Foto Struk / Bukti'),
            _ImagePickerWidget(
              image: _image,
              onTap: _showImageSourceSheet,
            ),

            const SizedBox(height: 32),
            FinaButton(
              label: 'Simpan Transaksi',
              onPressed: _submit,
              isLoading: _loading,
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _typeBtn(String type, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _type = type;
            _category = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _type == type ? FinaColors.copper : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _type == type ? Colors.white : FinaColors.text2,
                )),
          ),
        ),
      );

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

  void _showAccountPicker(List<AccountModel> list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickerSheet(
        title: 'Pilih Rekening',
        children: list
            .map((a) => ListTile(
                  leading:
                      IconCircle(icon: a.icon, bgColor: FinaColors.icCopper),
                  title: Text(a.name,
                      style: const TextStyle(color: FinaColors.text)),
                  subtitle: Text(formatCurrency(a.balance),
                      style: const TextStyle(
                          color: FinaColors.copper2, fontSize: 12)),
                  trailing: _account?.id == a.id
                      ? const Icon(Icons.check_rounded,
                          color: FinaColors.copper)
                      : null,
                  onTap: () {
                    setState(() => _account = a);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _showCategoryPicker(List<CategoryModel> list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickerSheet(
        title: 'Pilih Kategori',
        children: [
          ListTile(
            leading: const IconCircle(icon: 'x', bgColor: FinaColors.surface2),
            title: const Text('Tanpa kategori',
                style: TextStyle(color: FinaColors.text2)),
            onTap: () {
              setState(() => _category = null);
              Navigator.pop(context);
            },
          ),
          ...list.map((c) => ListTile(
                leading: IconCircle(icon: c.icon, bgColor: FinaColors.icCopper),
                title: Text(c.name,
                    style: const TextStyle(color: FinaColors.text)),
                trailing: _category?.id == c.id
                    ? const Icon(Icons.check_rounded, color: FinaColors.copper)
                    : null,
                onTap: () {
                  setState(() => _category = c);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Picker Widget
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePickerWidget extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  const _ImagePickerWidget({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                image!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            // Overlay hint
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Ganti',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: FinaColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FinaColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: FinaColors.text2, size: 20),
            SizedBox(width: 8),
            Text('Tambah foto struk (opsional)',
                style: TextStyle(fontSize: 13, color: FinaColors.text2)),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────
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

class _Picker extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  const _Picker(
      {required this.label,
      this.value,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: FinaColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FinaColors.border),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: FinaColors.text2),
            const SizedBox(width: 12),
            Expanded(
                child: Text(value ?? label,
                    style: TextStyle(
                        fontSize: 14,
                        color: value != null
                            ? FinaColors.text
                            : FinaColors.muted))),
            const Icon(Icons.chevron_right_rounded,
                color: FinaColors.text2, size: 18),
          ]),
        ),
      );
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _PickerSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const FinaDivider(),
          Flexible(
              child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 24),
            children: children,
          )),
        ],
      );
}
