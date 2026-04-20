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

// ── Providers di top-level ─────────────────────────────────────────────────────
final _editTxProvider =
    FutureProvider.autoDispose.family<TransactionModel, String>((ref, id) {
  return TransactionRepository().getById(id);
});

final _editAccountsProvider = FutureProvider.autoDispose<List<AccountModel>>(
    (_) => AccountRepository().getAll());

final _editCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>(
    (_) => CategoryRepository().getAll());

// ─────────────────────────────────────────────────────────────────────────────
class EditTransactionScreen extends ConsumerWidget {
  final String id;
  const EditTransactionScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_editTxProvider(id));
    return async.when(
      data: (tx) => _EditForm(tx: tx),
      loading: () => const Scaffold(
        backgroundColor: FinaColors.bg,
        body:
            Center(child: CircularProgressIndicator(color: FinaColors.copper)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: FinaColors.bg,
        appBar: AppBar(title: const Text('Edit Transaksi')),
        body: FinaErrorWidget(message: e.toString()),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _EditForm extends ConsumerStatefulWidget {
  final TransactionModel tx;
  const _EditForm({required this.tx});

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late String _type;
  late DateTime _date;
  AccountModel? _account;
  CategoryModel? _category;
  File? _newImage; // gambar baru yang dipilih
  bool _removeImage = false; // user minta hapus gambar lama
  bool _loading = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.tx.amount.toStringAsFixed(0));
    _noteCtrl = TextEditingController(text: widget.tx.note ?? '');
    _type = widget.tx.type;
    _date = DateTime.tryParse(widget.tx.date) ?? DateTime.now();
    _account = widget.tx.account;
    _category = widget.tx.category;
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
          source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _newImage = File(picked.path);
          _removeImage = false;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  void _showImageSourceSheet() {
    final hasExisting = widget.tx.imageUrl != null && !_removeImage;
    final hasNew = _newImage != null;

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
              child: Text('Foto Struk / Bukti',
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
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (hasExisting || hasNew)
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
                  setState(() {
                    _newImage = null;
                    _removeImage = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
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
        if (_account != null) 'account_id': _account!.id,
        if (_category != null) 'category_id': _category!.id,
        'type': _type,
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        if (_noteCtrl.text.isNotEmpty) 'note': _noteCtrl.text,
        if (_removeImage) 'remove_image': true,
      };

      if (_newImage != null) {
        await TransactionRepository()
            .updateWithImage(widget.tx.id, data, _newImage!.path);
      } else {
        await TransactionRepository().update(widget.tx.id, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi diperbarui ✅')));
        context.pop();
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
    final accounts = ref.watch(_editAccountsProvider);
    final categories = ref.watch(_editCategoriesProvider);

    // Tentukan gambar yang ditampilkan
    final showNewImage = _newImage != null;
    final showExistingImage =
        !_removeImage && !showNewImage && widget.tx.imageUrl != null;

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: const Text('Edit Transaksi'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Type switcher
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
          const SizedBox(height: 20),

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

          // Amount
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
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Rekening
          accounts.when(
            data: (list) => _PickerTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Rekening',
              value: _account?.name,
              onTap: () => _showAccountPicker(list),
            ),
            loading: () => const FinaSkeletonBox(height: 52, radius: 12),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 12),

          // Kategori
          categories.when(
            data: (list) {
              final filtered = list.where((c) => c.type == _type).toList();
              return _PickerTile(
                icon: Icons.category_outlined,
                label: 'Kategori',
                value: _category?.name,
                onTap: () => _showCategoryPicker(filtered),
              );
            },
            loading: () => const FinaSkeletonBox(height: 52, radius: 12),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 12),

          // Tanggal
          _PickerTile(
            icon: Icons.calendar_today_outlined,
            label: DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),

          // Catatan
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: FinaColors.text),
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Catatan...'),
          ),
          const SizedBox(height: 20),

          // ── Foto Struk ──────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('FOTO STRUK / BUKTI',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: FinaColors.text2)),
          ),
          const SizedBox(height: 8),

          if (showNewImage)
            _ExistingImageWidget(
              imageFile: _newImage,
              onChangeTap: _showImageSourceSheet,
            )
          else if (showExistingImage)
            _ExistingImageWidget(
              imageUrl: widget.tx.imageUrl,
              onChangeTap: _showImageSourceSheet,
            )
          else
            _EmptyImageWidget(onTap: _showImageSourceSheet),

          if (_removeImage)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: FinaColors.text2),
                const SizedBox(width: 6),
                const Text('Foto akan dihapus saat disimpan',
                    style: TextStyle(fontSize: 11, color: FinaColors.text2)),
              ]),
            ),

          const SizedBox(height: 28),
          FinaButton(
            label: 'Simpan Perubahan',
            onPressed: _save,
            isLoading: _loading,
          ),
          const SizedBox(height: 32),
        ]),
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
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Pilih Rekening',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: FinaColors.text))),
        const FinaDivider(),
        Flexible(
            child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 20),
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
        )),
      ]),
    );
  }

  void _showCategoryPicker(List<CategoryModel> list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Pilih Kategori',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: FinaColors.text))),
        const FinaDivider(),
        Flexible(
            child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            ListTile(
              leading:
                  const IconCircle(icon: 'x', bgColor: FinaColors.surface2),
              title: const Text('Tanpa kategori',
                  style: TextStyle(color: FinaColors.text2)),
              onTap: () {
                setState(() => _category = null);
                Navigator.pop(context);
              },
            ),
            ...list.map((c) => ListTile(
                  leading:
                      IconCircle(icon: c.icon, bgColor: FinaColors.icCopper),
                  title: Text(c.name,
                      style: const TextStyle(color: FinaColors.text)),
                  trailing: _category?.id == c.id
                      ? const Icon(Icons.check_rounded,
                          color: FinaColors.copper)
                      : null,
                  onTap: () {
                    setState(() => _category = c);
                    Navigator.pop(context);
                  },
                )),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image display widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Widget gambar yang sudah ada — bisa dari File lokal atau URL server.
/// Untuk URL server, inject Bearer token karena route dilindungi auth:sanctum.
class _ExistingImageWidget extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;
  final VoidCallback onChangeTap;

  const _ExistingImageWidget(
      {this.imageUrl, this.imageFile, required this.onChangeTap})
      : assert(imageUrl != null || imageFile != null);

  @override
  State<_ExistingImageWidget> createState() => _ExistingImageWidgetState();
}

class _ExistingImageWidgetState extends State<_ExistingImageWidget> {
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    if (widget.imageFile == null && widget.imageUrl != null) {
      _loadToken();
    }
  }

  Future<void> _loadToken() async {
    final token = await ApiService().getToken();
    if (mounted && token != null) {
      setState(() => _headers = {'Authorization': 'Bearer $token'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onChangeTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: widget.imageFile != null
                // ── Gambar baru dari lokal ──────────────────────────────────
                ? Image.file(
                    widget.imageFile!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  )
                // ── Gambar lama dari server ─────────────────────────────────
                : _headers == null
                    ? Container(
                        width: double.infinity,
                        height: 180,
                        color: FinaColors.surface2,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: FinaColors.copper),
                      )
                    : Image.network(
                        widget.imageUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        headers: _headers!,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                width: double.infinity,
                                height: 180,
                                color: FinaColors.surface2,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: FinaColors.copper,
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: FinaColors.surface2,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined,
                                  color: FinaColors.text2, size: 36),
                              SizedBox(height: 8),
                              Text('Gagal memuat gambar',
                                  style: TextStyle(
                                      fontSize: 11, color: FinaColors.text2)),
                            ],
                          ),
                        ),
                      ),
          ),
          // ── Label "Ganti" ───────────────────────────────────────────────
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('Ganti',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyImageWidget extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyImageWidget({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: FinaColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FinaColors.border),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: FinaColors.icBlue,
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.camera_alt_rounded,
                      color: FinaColors.blue, size: 16),
                  SizedBox(width: 6),
                  Text('Kamera',
                      style: TextStyle(
                          color: FinaColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: FinaColors.icGreen,
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.photo_library_rounded,
                      color: FinaColors.green, size: 16),
                  SizedBox(width: 6),
                  Text('Galeri',
                      style: TextStyle(
                          color: FinaColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('Tambah foto struk (opsional)',
                style: TextStyle(fontSize: 11, color: FinaColors.muted)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _PickerTile(
      {required this.icon,
      required this.label,
      this.value,
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
