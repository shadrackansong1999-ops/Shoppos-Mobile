/// App-wide constants. Mirrors python_api/core/auth.py so the mobile app's
/// permission model stays identical to the desktop app's.
library;

class AppInfo {
  static const String appName = 'ShopPOS Mobile';
  static const String dbFileName = 'shoppos_mobile.db';
  static const int dbVersion = 1;
}

/// Every permission key the app understands, with a human label - shown as
/// the hand-pick checklist on the Users screen. Keep this in sync with
/// ALL_PERMISSIONS in python_api/core/auth.py.
class Perm {
  static const dashboard = 'dashboard';
  static const monitor = 'monitor';
  static const pos = 'pos';
  static const products = 'products';
  static const categories = 'categories';
  static const suppliers = 'suppliers';
  static const customers = 'customers';
  static const orders = 'orders';
  static const productLogs = 'product_logs';
  static const sales = 'sales';
  static const mySales = 'my_sales';
  static const reports = 'reports';
  static const expenses = 'expenses';
  static const voidSale = 'void_sale';
  static const deleteSale = 'delete_sale';
  static const users = 'users';
  static const settings = 'settings';
  static const remote = 'remote';

  static const all = <String>[
    dashboard, monitor, pos, products, categories, suppliers, customers,
    orders, productLogs, sales, mySales, reports, expenses, voidSale,
    deleteSale, users, settings, remote,
  ];

  static const labels = <String, String>{
    dashboard: 'Dashboard',
    monitor: 'Live Monitor',
    pos: 'Point of Sale',
    products: 'Products',
    categories: 'Categories',
    suppliers: 'Suppliers',
    customers: 'Customers',
    orders: 'Purchase Orders',
    productLogs: 'Product Logs',
    sales: 'Sales History',
    mySales: 'My Sales',
    reports: 'Reports',
    expenses: 'Expenses',
    voidSale: 'Void a Sale',
    deleteSale: 'Permanently Delete a Sale',
    users: 'Users',
    settings: 'Settings',
    remote: 'Remote / Sync Info',
  };
}

/// Role -> default permission set, used when a user has no hand-picked
/// (custom) permission list saved for them.
class RoleDefaults {
  static const Map<String, List<String>> sets = {
    'admin': Perm.all,
    'manager': [
      Perm.dashboard, Perm.monitor, Perm.pos, Perm.products, Perm.categories,
      Perm.suppliers, Perm.customers, Perm.orders, Perm.productLogs,
      Perm.sales, Perm.mySales, Perm.reports, Perm.expenses, Perm.voidSale,
    ],
    'cashier': [Perm.pos, Perm.customers, Perm.mySales],
  };
}
