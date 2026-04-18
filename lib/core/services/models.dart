// ─────────────────────────────────────────────────────────────────────────────
// Models — sesuai response dari Laravel API
// Tidak memakai code-gen agar mudah di-edit manual
// ─────────────────────────────────────────────────────────────────────────────

// ── User ─────────────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String currency;
  final String timezone;
  final String? avatar;
  final String status;
  final String role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.timezone,
    this.avatar,
    required this.status,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        currency: j['currency'] ?? 'IDR',
        timezone: j['timezone'] ?? 'Asia/Jakarta',
        avatar: j['avatar'],
        status: j['status'] ?? 'active',
        role: j['role'] ?? 'user',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'currency': currency,
        'timezone': timezone,
        'avatar': avatar,
        'status': status,
        'role': role,
      };
}

// ── Account ───────────────────────────────────────────────────────────────────
class AccountModel {
  final String id;
  final String name;
  final double balance;
  final String? color;
  final String? icon;
  final String type;
  final bool isActive;

  const AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    this.color,
    this.icon,
    required this.type,
    required this.isActive,
  });

  factory AccountModel.fromJson(Map<String, dynamic> j) => AccountModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        balance: (j['balance'] ?? 0).toDouble(),
        color: j['color'],
        icon: j['icon'],
        type: j['type'] ?? 'cash',
        isActive: j['is_active'] ?? true,
      );
}

// ── Category ──────────────────────────────────────────────────────────────────
class CategoryModel {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final String type; // income | expense | transfer
  final String? parentId;

  const CategoryModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.type,
    this.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        color: j['color'],
        icon: j['icon'],
        type: j['type'] ?? 'expense',
        parentId: j['parent_id'],
      );
}

// ── Transaction ───────────────────────────────────────────────────────────────
class TransactionModel {
  final String id;
  final String type; // income | expense | transfer
  final double amount;
  final String date;
  final String? note;
  final String? imageUrl; // URL gambar struk/bukti transaksi
  final List<String> tags;
  final AccountModel? account;
  final CategoryModel? category;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    this.imageUrl,
    required this.tags,
    this.account,
    this.category,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
        id: j['id'] ?? '',
        type: j['type'] ?? 'expense',
        amount: (j['amount'] ?? 0).toDouble(),
        date: j['date'] ?? '',
        note: j['note'],
        imageUrl: j['image_url'],
        tags: List<String>.from(j['tags'] ?? []),
        account:
            j['account'] != null ? AccountModel.fromJson(j['account']) : null,
        category: j['category'] != null
            ? CategoryModel.fromJson(j['category'])
            : null,
      );

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isTransfer => type == 'transfer';
}

// ── Budget ────────────────────────────────────────────────────────────────────
class BudgetModel {
  final String id;
  final int month;
  final int year;
  final double amount;
  final double spent;
  final CategoryModel? category;
  final int? alertThreshold;

  const BudgetModel({
    required this.id,
    required this.month,
    required this.year,
    required this.amount,
    required this.spent,
    this.category,
    this.alertThreshold,
  });

  double get remaining => amount - spent;
  double get progress => amount > 0 ? (spent / amount).clamp(0, 1) : 0;
  bool get isOver => spent > amount;

  bool get isNearLimit {
    if (alertThreshold == null) return false;
    return (progress * 100) >= alertThreshold!;
  }

  factory BudgetModel.fromJson(Map<String, dynamic> j) => BudgetModel(
        id: j['id'] ?? '',
        month: int.tryParse(j['month'].toString()) ?? 1,
        year: int.tryParse(j['year'].toString()) ?? 2024,
        amount: (j['amount'] ?? 0).toDouble(),
        spent: (j['spent'] ?? 0).toDouble(),
        category: j['category'] != null
            ? CategoryModel.fromJson(j['category'])
            : null,
        alertThreshold: j['alert_threshold'] != null
            ? int.tryParse(j['alert_threshold'].toString())
            : null,
      );
}

// ── Recurring Plan ────────────────────────────────────────────────────────────
class RecurringPlanModel {
  final String id;
  final String name;
  final String type;
  final double amount;
  final String frequency; // daily | weekly | monthly | yearly
  final int? dayOfMonth;
  final String? nextDueDate;
  final bool isActive;
  final AccountModel? account;
  final CategoryModel? category;
  final DateTime? startDate;
  final DateTime? endsAt;
  final String? note;

  const RecurringPlanModel({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.frequency,
    this.dayOfMonth,
    this.nextDueDate,
    required this.isActive,
    this.account,
    this.category,
    this.startDate,
    this.endsAt,
    this.note,
  });

  factory RecurringPlanModel.fromJson(Map<String, dynamic> j) =>
      RecurringPlanModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'expense',
        amount: (j['amount'] ?? 0).toDouble(),
        frequency: j['frequency'] ?? 'monthly',
        dayOfMonth: j['day_of_month'],
        nextDueDate: j['next_due_date'],
        isActive: j['is_active'] ?? true,
        account:
            j['account'] != null ? AccountModel.fromJson(j['account']) : null,
        category: j['category'] != null
            ? CategoryModel.fromJson(j['category'])
            : null,
        startDate: j['start_date'] != null
            ? DateTime.tryParse(j['start_date'].toString())
            : null,
        endsAt: j['ends_at'] != null
            ? DateTime.tryParse(j['ends_at'].toString())
            : null,
        note: j['note'],
      );
}

// ── Notification ──────────────────────────────────────────────────────────────
class NotificationModel {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final String? readAt;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;
  String get title => data['title'] as String? ?? 'Notifikasi';
  String get message => data['message'] as String? ?? '';

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'] ?? '',
        type: j['type'] ?? '',
        data: Map<String, dynamic>.from(j['data'] ?? {}),
        readAt: j['read_at'],
        createdAt: j['created_at'] ?? '',
      );
}

// ── Dashboard Summary ─────────────────────────────────────────────────────────
class DashboardSummary {
  final double totalBalance;
  final double incomeThisMonth;
  final double expenseThisMonth;
  final double netThisMonth;
  final List<AccountModel> accounts;
  final List<TransactionModel> recentTransactions;

  const DashboardSummary({
    required this.totalBalance,
    required this.incomeThisMonth,
    required this.expenseThisMonth,
    required this.netThisMonth,
    required this.accounts,
    required this.recentTransactions,
  });

  static double parseToDouble(dynamic v) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
        totalBalance: parseToDouble(j['total_balance']),
        incomeThisMonth: parseToDouble(j['income']), // ✅ FIX
        expenseThisMonth: parseToDouble(j['expense']), // ✅ FIX
        netThisMonth: parseToDouble(j['balance']), // ✅ FIX
        accounts: (j['accounts'] as List? ?? [])
            .map((a) => AccountModel.fromJson(a))
            .toList(),
        recentTransactions: (j['recent_transactions'] as List? ?? [])
            .map((t) => TransactionModel.fromJson(t))
            .toList(),
      );
}

// ── Paginated Response ────────────────────────────────────────────────────────
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResponse(
      data: (json['data'] as List? ?? [])
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      total: meta['total'] ?? 0,
      perPage: meta['per_page'] ?? 20,
    );
  }
}
