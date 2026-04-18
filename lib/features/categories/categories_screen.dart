import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app_mobile/core/services/api_service.dart';
import 'package:finance_app_mobile/core/utils/bootstrap_icon_mapper.dart';
import '../../core/constants/theme.dart';
import '../../core/services/models.dart';
import '../../core/services/repositories.dart';
import '../../core/widgets/shared_widgets.dart';

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>(
    (_) => CategoryRepository().getAll());

// ─────────────────────────────────────────────────────────────────────────────
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _State();
}

class _State extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: const Text('Kategori'),
        bottom: TabBar(
          controller: _tab,
          labelColor: FinaColors.copper,
          unselectedLabelColor: FinaColors.text2,
          indicatorColor: FinaColors.copper,
          tabs: const [Tab(text: 'Pengeluaran'), Tab(text: 'Pemasukan')],
        ),
      ),
      body: async.when(
        data: (cats) => TabBarView(
          controller: _tab,
          children: [
            _CategoryList(
              categories: cats.where((c) => c.type == 'expense').toList(),
              onRefresh: () => ref.refresh(categoriesProvider),
              onAdd: () => _showForm(context, ref, type: 'expense'),
            ),
            _CategoryList(
              categories: cats.where((c) => c.type == 'income').toList(),
              onRefresh: () => ref.refresh(categoriesProvider),
              onAdd: () => _showForm(context, ref, type: 'income'),
            ),
          ],
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: FinaColors.copper)),
        error: (e, _) => FinaErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(categoriesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref,
            type: _tab.index == 0 ? 'expense' : 'income'),
        backgroundColor: FinaColors.copper,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref,
      {required String type, CategoryModel? cat}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FinaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CategoryForm(
        type: type,
        category: cat,
        onSaved: () => ref.refresh(categoriesProvider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  final VoidCallback onRefresh, onAdd;
  const _CategoryList({
    required this.categories,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return FinaEmptyState(
        emoji: '📂',
        title: 'Belum ada kategori',
        subtitle: 'Tambah kategori untuk mengorganisir transaksimu',
        action: FinaButton(label: 'Tambah Kategori', onPressed: onAdd),
      );
    }

    return RefreshIndicator(
      color: FinaColors.copper,
      backgroundColor: FinaColors.surface,
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) =>
            _CategoryTile(category: categories[i], onRefresh: onRefresh),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onRefresh;
  const _CategoryTile({required this.category, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FinaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Icon(
          BootstrapIconMapper.get(category.icon),
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(category.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600))),
        PopupMenuButton<String>(
          color: FinaColors.surface2,
          onSelected: (v) async {
            if (v == 'delete') {
              try {
                await CategoryRepository().delete(category.id);
                onRefresh();
              } on ApiException catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus', style: TextStyle(color: FinaColors.red))),
          ],
          child: const Icon(Icons.more_vert_rounded, color: FinaColors.text2),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CategoryForm extends StatefulWidget {
  final String type;
  final CategoryModel? category;
  final VoidCallback onSaved;
  const _CategoryForm(
      {required this.type, this.category, required this.onSaved});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _nameCtrl = TextEditingController();
  String _icon = '📌';
  bool _loading = false;

  static const _icons = [
    '🏠',
    '🚗',
    '🛒',
    '🍔',
    '☕',
    '🎮',
    '💊',
    '📚',
    '✈️',
    '🏋️',
    '💰',
    '💳',
    '🎁',
    '👗',
    '💄',
    '🎵',
    '🎬',
    '⚽',
    '🐾',
    '🌿',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _icon = widget.category!.icon ?? '📌';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'type': widget.type,
        'icon': _icon,
      };
      if (widget.category == null) {
        await CategoryRepository().create(data);
      } else {
        await CategoryRepository().update(widget.category!.id, data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.category == null ? 'Tambah Kategori' : 'Edit Kategori',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),

        // Icon picker
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _icons
              .map((ic) => GestureDetector(
                    onTap: () => setState(() => _icon = ic),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _icon == ic
                            ? FinaColors.icCopper
                            : FinaColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _icon == ic
                                ? FinaColors.copper
                                : FinaColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(ic, style: const TextStyle(fontSize: 18)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: FinaColors.text),
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        const SizedBox(height: 20),
        FinaButton(
          label: widget.category == null ? 'Tambah' : 'Simpan',
          onPressed: _save,
          isLoading: _loading,
        ),
      ]),
    );
  }
}
