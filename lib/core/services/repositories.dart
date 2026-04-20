import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: extract data dari response
// ─────────────────────────────────────────────────────────────────────────────
T _d<T>(Map<String, dynamic> res, T Function(dynamic) mapper) {
  try {
    return mapper(res['data']);
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Repository
// ─────────────────────────────────────────────────────────────────────────────
class AuthRepository {
  final ApiService _api;
  AuthRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    try {
      final res = await _api.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
        if (deviceName != null) 'device_name': deviceName,
      });
      return (
        token: res['data']['token'] as String,
        user: UserModel.fromJson(res['data']['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<({String token, UserModel user})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String currency = 'IDR',
    String timezone = 'Asia/Jakarta',
  }) async {
    try {
      final res = await _api.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'currency': currency,
        'timezone': timezone,
      });
      return (
        token: res['data']['token'] as String,
        user: UserModel.fromJson(res['data']['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } on DioException catch (_) {} // silent
    await _api.clearToken();
  }

  Future<UserModel> getMe() async {
    try {
      final res = await _api.get(ApiConstants.me);
      return UserModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _api.put(ApiConstants.updateMe, data: data);
      return UserModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _api.put(ApiConstants.changePass, data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resendVerification() async {
    try {
      await _api.post(ApiConstants.emailResend);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      final res = await _api.get(ApiConstants.emailStatus);
      return res['data']['email_verified'] as bool? ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Repository
// ─────────────────────────────────────────────────────────────────────────────
class DashboardRepository {
  final ApiService _api;

  DashboardRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<DashboardSummary> getSummary() async {
    try {
      final res = await _api.get(ApiConstants.dashboard);
      final data = res['data'];
      final summary = data['summary'];
      return DashboardSummary.fromJson({
        ...summary,
        'accounts': data['accounts'],
        'recent_transactions': data['recent_transactions'],
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getCharts() async {
    try {
      final res = await _api.get(ApiConstants.dashboardCharts);
      return res['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Repository
// ─────────────────────────────────────────────────────────────────────────────
class TransactionRepository {
  final ApiService _api;
  TransactionRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<PaginatedResponse<TransactionModel>> getAll({
    int? month,
    int? year,
    String? type,
    String? accountId,
    String? categoryId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final res = await _api.get(ApiConstants.transactions, params: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
        if (type != null) 'type': type,
        if (accountId != null) 'account_id': accountId,
        if (categoryId != null) 'category_id': categoryId,
        if (search != null) 'search': search,
        'page': page,
        'per_page': perPage,
      });
      return PaginatedResponse.fromJson(res, TransactionModel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TransactionModel> getById(String id) async {
    try {
      final res = await _api.get('${ApiConstants.transactions}/$id');
      return TransactionModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TransactionModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.transactions, data: data);
      return TransactionModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Buat transaksi dengan gambar (multipart/form-data)
  Future<TransactionModel> createWithImage(
    Map<String, dynamic> data,
    String imagePath,
  ) async {
    try {
      final Map<String, dynamic> formFields =
          data.map((k, v) => MapEntry(k, v is num ? v.toString() : v));

      final formData = FormData.fromMap({
        ...formFields,
        'receipt': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      });

      final res = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.transactions,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return TransactionModel.fromJson(
          res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TransactionModel> update(String id, Map<String, dynamic> data) async {
    try {
      final res =
          await _api.put('${ApiConstants.transactions}/$id', data: data);
      return TransactionModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Update transaksi dengan gambar baru (multipart/form-data)
  Future<TransactionModel> updateWithImage(
    String id,
    Map<String, dynamic> data,
    String imagePath,
  ) async {
    try {
      final Map<String, dynamic> formFields =
          data.map((k, v) => MapEntry(k, v is num ? v.toString() : v));

      final formData = FormData.fromMap({
        ...formFields,
        '_method': 'PUT', // Laravel method spoofing
        'receipt': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      });

      final res = await _api.dio.post<Map<String, dynamic>>(
        '${ApiConstants.transactions}/$id',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return TransactionModel.fromJson(
          res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('${ApiConstants.transactions}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getSummary({int? month, int? year}) async {
    try {
      final res = await _api.get(ApiConstants.transactionSummary, params: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      });
      return res['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String date,
    String? note,
  }) async {
    try {
      final res = await _api.post(ApiConstants.transactionTransfer, data: {
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'amount': amount,
        'date': date,
        if (note != null) 'note': note,
      });
      return res['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Repository
// ─────────────────────────────────────────────────────────────────────────────
class AccountRepository {
  final ApiService _api;
  AccountRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<List<AccountModel>> getAll() async {
    try {
      final res = await _api.get(ApiConstants.accounts);
      return (res['data'] as List)
          .map((e) => AccountModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<double> getTotalBalance() async {
    try {
      final res = await _api.get(ApiConstants.totalBalance);
      return (res['data']['total_balance'] ?? 0).toDouble();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AccountModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.accounts, data: data);
      return AccountModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AccountModel> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('${ApiConstants.accounts}/$id', data: data);
      return AccountModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('${ApiConstants.accounts}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Repository
// ─────────────────────────────────────────────────────────────────────────────
class CategoryRepository {
  final ApiService _api;
  CategoryRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<List<CategoryModel>> getAll() async {
    try {
      final res = await _api.get(ApiConstants.categoriesFlat);
      return (res['data'] as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CategoryModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.categories, data: data);
      return CategoryModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CategoryModel> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('${ApiConstants.categories}/$id', data: data);
      return CategoryModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('${ApiConstants.categories}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget Repository
// ─────────────────────────────────────────────────────────────────────────────
class BudgetRepository {
  final ApiService _api;
  BudgetRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<List<BudgetModel>> getAll({int? month, int? year}) async {
    try {
      final res = await _api.get(ApiConstants.budgets, params: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      });
      return (res['data']['budgets'] as List)
          .map((e) => BudgetModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<BudgetModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.budgets, data: data);
      return BudgetModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<BudgetModel> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('${ApiConstants.budgets}/$id', data: data);
      return BudgetModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('${ApiConstants.budgets}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> copyFromLastMonth() async {
    try {
      await _api.post(ApiConstants.budgetCopyLast);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recurring Plan Repository
// ─────────────────────────────────────────────────────────────────────────────
class RecurringRepository {
  final ApiService _api;
  RecurringRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<List<RecurringPlanModel>> getAll() async {
    try {
      final res = await _api.get(ApiConstants.recurring);
      return (res['data'] as List)
          .map((e) => RecurringPlanModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<RecurringPlanModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.recurring, data: data);
      return RecurringPlanModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<RecurringPlanModel> update(
      String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('${ApiConstants.recurring}/$id', data: data);
      return RecurringPlanModel.fromJson(res['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('${ApiConstants.recurring}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> toggle(String id) async {
    try {
      await _api.patch('${ApiConstants.recurring}/$id/toggle');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Repository
// ─────────────────────────────────────────────────────────────────────────────
class NotificationRepository {
  final ApiService _api;
  NotificationRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<PaginatedResponse<NotificationModel>> getAll({int page = 1}) async {
    try {
      final res =
          await _api.get(ApiConstants.notifications, params: {'page': page});
      return PaginatedResponse.fromJson(res, NotificationModel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await _api.get(ApiConstants.notifUnreadCount);
      return res['data']['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.post(ApiConstants.notifReadAll);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.post('${ApiConstants.notifications}/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteAll() async {
    try {
      await _api.delete(ApiConstants.notifDeleteAll);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('${ApiConstants.notifications}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Import Repository
// ─────────────────────────────────────────────────────────────────────────────
class ImportRepository {
  final ApiService _api;
  ImportRepository([ApiService? api]) : _api = api ?? ApiService();

  /// Upload & import CSV langsung ke server.
  /// [filePath]    : path lokal file CSV di device
  /// [fileName]    : nama file (untuk multipart)
  /// [accountId]   : UUID rekening tujuan
  /// [bank]        : nama bank (BCA, Mandiri, dst.)
  /// [dateFormat]  : format tanggal di CSV, misal "d/M/yyyy"
  /// [typeDefault] : tipe default transaksi jika tidak terdeteksi otomatis
  Future<ImportResultModel> upload({
    required String filePath,
    required String fileName,
    required String accountId,
    required String bank,
    required String dateFormat,
    required String typeDefault,
  }) async {
    try {
      final formData = FormData.fromMap({
        'account_id': accountId,
        'bank': bank,
        'date_format': dateFormat,
        'type_default': typeDefault,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final res = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.importUpload,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return ImportResultModel.fromJson(
          res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
