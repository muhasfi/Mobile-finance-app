class ApiConstants {
  ApiConstants._();

  static const baseUrl = 'https://projecthasfi2.my.id/api';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const updateMe = '/auth/me';
  static const changePass = '/auth/me/password';
  static const forgotPass = '/auth/forgot-password';
  static const resetPass = '/auth/reset-password';

  // Dashboard
  static const dashboard = '/dashboard';
  static const dashboardCharts = '/dashboard/charts';

  // Transactions
  static const transactions = '/transactions';
  static const transactionSummary = '/transactions/summary';
  static const transactionTransfer = '/transactions/transfer';

  // Accounts
  static const accounts = '/accounts';
  static const totalBalance = '/accounts/total-balance';

  // Categories
  static const categories = '/categories';
  static const categoriesFlat = '/categories/flat';

  // Budget
  static const budgets = '/budgets';
  static const budgetCopyLast = '/budgets/copy';

  // Recurring
  static const recurring = '/recurring';

  // Reports
  static const reportMonthly = '/reports/monthly';
  static const reportTrend = '/reports/trend';
  static const reportRange = '/reports/range';
  static const reportComparison = '/reports/comparison';
  static const reportFilterMeta = '/reports/filterMeta';
  static const reportExportCsv = '/reports/exportCsv';
  static const reportExportPdf = '/reports/exportPdf';

  // Notifications
  static const notifications = '/notifications';
  static const notifUnreadCount = '/notifications/unread-count';
  static const notifReadAll = '/notifications/read-all';
  static const notifDeleteAll = '/notifications/all';

  // AI
  static const aiChat = '/ai/chat';
  static const aiChatReset = '/ai/chat/reset';
  static const aiInsights = '/ai/insights';
  static const aiInsightsGen = '/ai/insights/generate';

  // Import CSV (multipart/form-data)
  static const importUpload = '/import/upload';
  static const importConfirm = '/import/confirm';
}
