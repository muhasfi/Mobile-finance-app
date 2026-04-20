import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart';

// ── Step enum ─────────────────────────────────────────────────────────────────
enum _Step { upload, preview, done }

// ── Preview row model ─────────────────────────────────────────────────────────
class _PreviewRow {
  final String date, description, amount, type;
  const _PreviewRow({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
const _banks = ['BCA', 'Mandiri', 'BRI', 'BNI', 'CIMB', 'Permata', 'Lainnya'];

const _dateFormats = [
  'd/M/yyyy',
  'dd/MM/yyyy',
  'yyyy-MM-dd',
  'MM/dd/yyyy',
  'd-M-yyyy',
];

// ─────────────────────────────────────────────────────────────────────────────
// ImportCsvTab — dipakai sebagai tab di ReportsScreen (tanpa Scaffold)
// ─────────────────────────────────────────────────────────────────────────────
class ImportCsvTab extends ConsumerStatefulWidget {
  const ImportCsvTab({super.key});

  @override
  ConsumerState<ImportCsvTab> createState() => _ImportCsvBodyState();
}

// ─────────────────────────────────────────────────────────────────────────────
// ImportCsvScreen — standalone route (dengan Scaffold + AppBar)
// ─────────────────────────────────────────────────────────────────────────────
class ImportCsvScreen extends ConsumerStatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  ConsumerState<ImportCsvScreen> createState() => _State();
}

class _ImportCsvBodyState extends ConsumerState<ImportCsvTab> {
  _Step _step = _Step.upload;
  String _bank = 'BCA';
  String? _fileName;
  String? _filePath;
  int _rowCount = 0;
  bool _loading = false;
  String? _error;

  List<_PreviewRow> _preview = [];

  String _dateFormat = 'd/M/yyyy';
  String _typeDefault = 'expense';
  AccountModel? _account;

  // ── FIX: future dibuat sekali di initState, bukan setiap rebuild ─────────
  late Future<List<AccountModel>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = AccountRepository().getAll();
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Back button row saat step > upload
      if (_step != _Step.upload)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(children: [
            TextButton.icon(
              onPressed: () => setState(() {
                _step = _Step.upload;
                _error = null;
              }),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Kembali'),
              style: TextButton.styleFrom(foregroundColor: FinaColors.text2),
            ),
          ]),
        ),
      _StepIndicator(current: _step),
      Expanded(child: _buildBody()),
    ]);
  }

  Widget _buildBody() {
    return switch (_step) {
      _Step.upload => _buildUploadStep(),
      _Step.preview => _buildPreviewStep(),
      _Step.done => _buildDoneStep(),
    };
  }

  // ── Step 1: Upload ──────────────────────────────────────────────────────────
  Widget _buildUploadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) ...[
          FinaCard(
            copper: true,
            padding: const EdgeInsets.all(12),
            child: Text(_error!,
                style: const TextStyle(color: FinaColors.red, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],

        // Upload zone
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0x07C8783A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _fileName != null
                    ? FinaColors.copper
                    : const Color(0x59C8783A),
                width: 2,
              ),
            ),
            child: Column(children: [
              Text(
                _fileName == null ? '📂' : '✅',
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 10),
              Text(
                _fileName ?? 'Upload File CSV',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _fileName == null
                    ? 'Tap untuk pilih file mutasi bank (.csv)'
                    : 'Tap untuk ganti file',
                style: const TextStyle(fontSize: 11, color: FinaColors.text2),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 10),
                FinaPill('$_rowCount baris terdeteksi',
                    variant: PillVariant.copper),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 20),

        // Bank selector
        const _Label('Format Bank'),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: _banks.map((b) {
            final active = _bank == b;
            return GestureDetector(
              onTap: () => setState(() => _bank = b),
              child: Container(
                decoration: BoxDecoration(
                  color: active ? FinaColors.icCopper : FinaColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: active ? FinaColors.copper : FinaColors.border),
                ),
                alignment: Alignment.center,
                child: Text(b,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? FinaColors.copper : FinaColors.text2,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Account selector — FIX: pakai _accountsFuture bukan AccountRepository().getAll()
        const _Label('Rekening Tujuan'),
        FutureBuilder<List<AccountModel>>(
          future: _accountsFuture,
          builder: (_, snap) {
            final accounts = snap.data ?? [];
            // FIX: pastikan _account ada di list sebelum dijadikan value
            final validAccount =
                accounts.any((a) => a.id == _account?.id) ? _account : null;
            return DropdownButtonFormField<AccountModel>(
              value: validAccount,
              dropdownColor: FinaColors.surface2,
              decoration: const InputDecoration(labelText: 'Pilih Rekening'),
              items: accounts
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.name,
                            style: const TextStyle(color: FinaColors.text)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _account = v),
            );
          },
        ),
        const SizedBox(height: 16),

        // Date format
        const _Label('Format Tanggal di CSV'),
        DropdownButtonFormField<String>(
          value: _dateFormat,
          dropdownColor: FinaColors.surface2,
          decoration: const InputDecoration(labelText: 'Format Tanggal'),
          items: _dateFormats
              .map((f) => DropdownMenuItem(
                    value: f,
                    child:
                        Text(f, style: const TextStyle(color: FinaColors.text)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _dateFormat = v!),
        ),
        const SizedBox(height: 16),

        // Default type
        const _Label('Tipe Default Transaksi'),
        Row(children: [
          Expanded(
              child: _TypeBtn(
            'expense',
            '📤 Pengeluaran',
            _typeDefault == 'expense',
            () => setState(() => _typeDefault = 'expense'),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: _TypeBtn(
            'income',
            '📥 Pemasukan',
            _typeDefault == 'income',
            () => setState(() => _typeDefault = 'income'),
          )),
        ]),
        const SizedBox(height: 32),

        FinaButton(
          label: _fileName == null ? 'Pilih File Dulu' : 'Lanjut Preview',
          onPressed: _fileName == null ? null : _goToPreview,
          isLoading: _loading,
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Step 2: Preview ─────────────────────────────────────────────────────────
  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FinaCard(
          copper: true,
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Text('📊', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Preview · $_rowCount baris terdeteksi',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(_fileName ?? '',
                  style:
                      const TextStyle(fontSize: 11, color: FinaColors.text2)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        FinaCard(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            const Row(children: [
              Expanded(
                  flex: 2,
                  child: Text('Tanggal',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: FinaColors.text2))),
              Expanded(
                  flex: 3,
                  child: Text('Keterangan',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: FinaColors.text2))),
              Expanded(
                  flex: 2,
                  child: Text('Jumlah',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: FinaColors.text2),
                      textAlign: TextAlign.right)),
            ]),
            const SizedBox(height: 8),
            const FinaDivider(),
            ..._preview.map((row) => Column(children: [
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        flex: 2,
                        child: Text(row.date,
                            style: const TextStyle(
                                fontSize: 11, color: FinaColors.text2))),
                    Expanded(
                        flex: 3,
                        child: Text(row.description,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Expanded(
                        flex: 2,
                        child: Text(
                          row.amount,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: row.type == 'income'
                                ? FinaColors.green
                                : FinaColors.red,
                          ),
                          textAlign: TextAlign.right,
                        )),
                  ]),
                  const SizedBox(height: 8),
                  const FinaDivider(),
                ])),
          ]),
        ),
        const SizedBox(height: 24),
        FinaButton(
          label: 'Import $_rowCount Transaksi',
          onPressed: _import,
          isLoading: _loading,
        ),
        const SizedBox(height: 8),
        FinaButton(
          label: 'Kembali',
          outline: true,
          onPressed: () => setState(() => _step = _Step.upload),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Step 3: Done ────────────────────────────────────────────────────────────
  Widget _buildDoneStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: FinaColors.icGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Text('✅', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 20),
            const Text('Import Berhasil!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '$_rowCount transaksi berhasil diimpor ke rekening ${_account?.name ?? ""}',
              style: const TextStyle(
                  fontSize: 13, color: FinaColors.text2, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FinaButton(
              label: 'Lihat Transaksi',
              onPressed: () => context.go('/transactions'),
            ),
            const SizedBox(height: 12),
            FinaButton(
              label: 'Import Lagi',
              outline: true,
              onPressed: () => setState(() {
                _step = _Step.upload;
                _fileName = null;
                _filePath = null;
                _preview = [];
                _rowCount = 0;
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logic ───────────────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final estimatedRows =
            ((file.size ?? 1000) / 60).round().clamp(1, 99999);

        setState(() {
          _fileName = file.name;
          _filePath = file.path;
          _rowCount = estimatedRows;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Gagal membuka file: $e');
    }
  }

  void _goToPreview() {
    if (_account == null) {
      setState(() => _error = 'Pilih rekening tujuan terlebih dahulu');
      return;
    }
    if (_filePath == null) {
      setState(() => _error = 'Pilih file CSV terlebih dahulu');
      return;
    }

    setState(() {
      _error = null;
      _preview = [
        const _PreviewRow(
            date: '11/04',
            description: 'Makan Siang',
            amount: '−45.000',
            type: 'expense'),
        const _PreviewRow(
            date: '11/04',
            description: 'Transfer Masuk',
            amount: '+8.200.000',
            type: 'income'),
        const _PreviewRow(
            date: '10/04',
            description: 'GoCar',
            amount: '−28.000',
            type: 'expense'),
        const _PreviewRow(
            date: '10/04',
            description: 'Belanja Groceries',
            amount: '−215.000',
            type: 'expense'),
        const _PreviewRow(
            date: '09/04',
            description: 'Gaji April',
            amount: '+15.000.000',
            type: 'income'),
      ];
      _step = _Step.preview;
    });
  }

  Future<void> _import() async {
    if (_account == null || _filePath == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final formData = FormData.fromMap({
        'account_id': _account!.id,
        'bank': _bank,
        'date_format': _dateFormat,
        'type_default': _typeDefault,
        'file': await MultipartFile.fromFile(
          _filePath!,
          filename: _fileName,
        ),
      });

      await ApiService().dio.post(
            '/import/upload',
            data: formData,
          );

      if (mounted)
        setState(() {
          _step = _Step.done;
        });
    } on DioException catch (e) {
      setState(() => _error = ApiException.fromDio(e).message);
    } catch (e) {
      setState(() => _error = 'Gagal mengimpor: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _State — standalone screen wrapper (untuk route /import)
// ─────────────────────────────────────────────────────────────────────────────
class _State extends ConsumerState<ImportCsvScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: const Text('Import CSV Bank'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: const SafeArea(child: ImportCsvTab()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final _Step current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const steps = _Step.values;
    const labels = ['Upload', 'Preview', 'Selesai'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final done = steps[stepIdx].index <= current.index;
            return Expanded(
                child: Container(
              height: 2,
              color: done ? FinaColors.copper : FinaColors.surface2,
            ));
          }
          final idx = i ~/ 2;
          final step = steps[idx];
          final done = step.index <= current.index;
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? FinaColors.copper : FinaColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(
                  color: done ? FinaColors.copper : FinaColors.border),
            ),
            alignment: Alignment.center,
            child: done && step.index < current.index
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text('${idx + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: done ? Colors.white : FinaColors.text2,
                    )),
          );
        }),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: FinaColors.text2,
            )),
      );
}

class _TypeBtn extends StatelessWidget {
  final String value, label;
  final bool active;
  final VoidCallback onTap;
  const _TypeBtn(this.value, this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? FinaColors.copper : FinaColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active ? FinaColors.copper : FinaColors.border),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : FinaColors.text2,
              )),
        ),
      );
}
