import 'package:flutter/widgets.dart';

// provide the two supported interface languages
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('zh')];

  // use english for isolated widgets without the app delegate
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  bool get isChinese => locale.languageCode == 'zh';

  // replace named values inside translated messages
  String text(String key, [Map<String, Object> values = const {}]) {
    var result = (isChinese ? _zh : _en)[key] ?? _en[key] ?? key;
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return result;
  }

  // translate stable category identifiers only for display
  String category(String value) {
    final key = 'category.$value';
    return (isChinese ? _zh : _en)[key] ?? _en[key] ?? value;
  }

  // translate messages produced outside the widget layer
  String message(String value) {
    if (!isChinese) return value;
    return _zhMessages[value] ?? value;
  }

  // format dates for the active language
  String date(DateTime value) => isChinese
      ? '${value.year}年${value.month}月${value.day}日'
      : '${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}/${value.year}';

  // format month headings for the active language
  String month(DateTime value) => isChinese
      ? '${value.year}年${value.month}月'
      : '${_months[value.month - 1]} ${value.year}';

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // store english interface text by stable keys
  static const _en = <String, String>{
    'language': 'Language',
    'english': 'English',
    'chinese': '简体中文',
    'home': 'Home',
    'expenses': 'Expenses',
    'convert': 'Convert',
    'settings': 'Settings',
    'signIn': 'SIGN IN',
    'profile': 'Profile',
    'addExpense': 'Add expense',
    'retryTransfer': 'Retry transfer',
    'transferFailed':
        'Couldn’t transfer guest expenses. Keep the app open and retry.',
    'transferSaving': 'Saving {count} guest expenses to your account…',
    'home.title': 'Your money, wherever you go.',
    'home.subtitle': 'A little clarity for the month ahead.',
    'home.spent': 'Spent this month',
    'home.expenseCount': '{count} {label}',
    'home.expense': 'expense',
    'home.expenses': 'expenses',
    'home.loadingSpending': 'Loading monthly spending',
    'home.spendingError': 'Couldn’t load monthly spending.',
    'home.retrySpending': 'Retry spending',
    'home.noExpenses': 'No expenses this month',
    'home.monthlyBudget': 'Monthly budget',
    'home.editBudget': 'Edit budget',
    'home.loadingBudget': 'Loading monthly budget',
    'home.budgetError': 'Couldn’t load your budget.',
    'home.retryBudget': 'Retry budget',
    'home.noBudget': 'No monthly budget',
    'home.setBudget': 'Set budget',
    'home.overBudget': 'Over budget by',
    'home.remaining': 'Remaining',
    'home.remainingUnavailable':
        'Remaining balance unavailable while spending loads.',
    'home.categories': 'Spending by category',
    'home.categorySubtitle': 'Share of this month’s USD spending',
    'home.loadingCategories': 'Loading category spending',
    'home.categoryError': 'Couldn’t load category spending.',
    'home.retryCategories': 'Retry categories',
    'home.viewExpenses': 'View expenses',
    'home.converter': 'Converter',
    'monthly.title': 'This month’s expenses',
    'monthly.categoryTitle': '{category} expenses',
    'monthly.clearFilter': 'Clear category filter',
    'monthly.empty': 'No expenses this month.',
    'monthly.emptyCategory': 'No {category} expenses this month.',
    'settings.title': 'Make room for your goals.',
    'settings.guest': 'Guest mode',
    'settings.guestNote':
        'Guest expenses are temporary and transfer when you sign in.',
    'settings.tagline': 'Pockit · Your money, wherever you go.',
    'settings.budget': 'Monthly budget',
    'settings.budgetHelp': 'Set a monthly spending limit in USD.',
    'settings.loadingBudget': 'Loading budget',
    'settings.retryBudgetLoad': 'Retry loading budget',
    'settings.noBudget': 'No budget yet',
    'settings.currentBudget': 'Current budget: {amount} USD',
    'settings.budgetAmount': 'Budget amount',
    'settings.saveBudget': 'Save budget',
    'settings.savingBudget': 'Saving… connection required',
    'settings.retryBudgetSave': 'Retry saving budget',
    'settings.guestBudgetSaving': 'Saving your guest budget to this account…',
    'settings.retryBudgetTransfer': 'Retry budget transfer',
    'settings.defaultCurrency': 'Default currency',
    'settings.newExpenses': 'New expenses',
    'settings.loadingCurrency': 'Loading preferred currency',
    'settings.retryCurrencyLoad': 'Retry loading currency',
    'settings.retryCurrencySave': 'Retry saving currency',
    'settings.savingCurrency': 'Saving preferred currency',
    'settings.customCategories': 'Custom categories',
    'settings.categoryLimit': 'Add up to 10 categories.',
    'settings.loadingCategories': 'Loading custom categories',
    'settings.retryCategoryLoad': 'Retry loading categories',
    'settings.categoryName': 'Category name',
    'settings.addCategory': 'Add category',
    'settings.noCustomCategories': 'No custom categories yet.',
    'settings.removeCategory': 'Remove {category}',
    'settings.savingCategories': 'Saving custom categories',
    'settings.retryCategorySave': 'Retry saving categories',
    'category.Housing': 'Housing',
    'category.Groceries': 'Groceries',
    'category.Dining': 'Dining',
    'category.Transportation': 'Transportation',
    'category.Bills': 'Bills',
    'category.Subscriptions': 'Subscriptions',
    'category.Shopping': 'Shopping',
    'category.Entertainment': 'Entertainment',
    'category.Travel': 'Travel',
    'category.Health': 'Health',
    'category.Education': 'Education',
    'category.Other': 'Other',
    'category.all': 'All categories',
    'category.empty': 'No expenses for this month yet.',
    'category.label': 'Category',
    'previousMonth': 'Previous month',
    'nextMonth': 'Next month',
    'thisMonth': 'This month',
    'chooseMonthYear': 'Choose month and year',
    'month': 'Month',
    'year': 'Year',
    'cancel': 'Cancel',
    'done': 'Done',
    'delete': 'Delete',
    'retry': 'Retry',
    'expenses.title': 'Every purchase, in perspective.',
    'expenses.subtitle': 'Original currency. One clear USD total.',
    'expenses.deleteTitle': 'Delete expense?',
    'expenses.deleted': 'Expense deleted',
    'expenses.deleteError': 'Couldn’t delete. Please retry.',
    'expenses.undo': 'Undo',
    'expenses.restoreError': 'Couldn’t restore. Please retry.',
    'expenses.rateDate': 'Rate date: {date}',
    'expenses.retryLoad': 'Retry loading expenses',
    'expenses.empty':
        'No expenses yet. Add your first purchase to get started.',
    'expenses.emptyMonth': 'No expenses in this month.',
    'expenses.emptyCategory': 'No expenses in this category.',
    'expenseForm.edit': 'Edit expense',
    'expenseForm.amount': 'Expense amount',
    'expenseForm.currency': 'Currency',
    'expenseForm.date': 'Date: {date}',
    'expenseForm.description': 'Description (optional)',
    'expenseForm.rateHelp': 'Foreign amounts use the latest daily rate. The saved USD value stays fixed.',
    'expenseForm.savedRate': 'Saved: {amount} USD · rate date {date}',
    'expenseForm.saveError': 'Couldn’t save. Please retry.',
    'expenseForm.saving': 'Saving… connection required',
    'expenseForm.save': 'Save expense',
    'converter.title': 'A world of possibilities.',
    'converter.subtitle': 'Check a currency before your next adventure.',
    'converter.amount': 'Amount',
    'converter.amountHint': 'Enter an amount',
    'converter.from': 'From',
    'converter.to': 'To',
    'converter.swap': 'Swap currencies',
    'converter.conversion': 'Conversion',
    'converter.refresh': 'Refresh rate',
    'converter.fetching': 'Fetching exchange rate',
    'converter.enterAmount': 'Enter an amount',
    'converter.checkAmount': 'Check the amount above.',
    'converter.noExchange': 'No exchange needed',
    'converter.addExpense': 'Add as expense',
    'converter.note': 'Frankfurter rates may vary from your bank.',
    'account.title': 'Account',
    'account.syncing': 'Syncing changes',
    'account.syncIssue': 'Sync needs attention',
    'account.syncOn': 'Cloud sync on',
    'account.savedCount': '{count} {label} saved',
    'account.signingOut': 'Signing out…',
    'account.signOut': 'Sign out',
    'account.signOutTitle': 'Sign out?',
    'account.signOutSyncing':
        'Your changes are still syncing. Sign out anyway?',
    'account.signOutQuestion': 'Sign out of this account?',
    'auth.title': 'Your account',
    'auth.registerGreeting': 'Make yourself at home.',
    'auth.signInGreeting': 'Welcome back.',
    'auth.tagline': 'Your money, wherever you go.',
    'auth.email': 'Email',
    'auth.password': 'Password',
    'auth.emailError': 'Enter a valid email address.',
    'auth.passwordError': 'Enter your password.',
    'auth.passwordLength': 'Use at least 6 characters.',
    'auth.showPassword': 'Show password',
    'auth.hidePassword': 'Hide password',
    'auth.wait': 'Please wait…',
    'auth.create': 'Create account',
    'auth.signIn': 'Sign in',
    'auth.or': 'or',
    'auth.google': 'Continue with Google',
    'auth.haveAccount': 'Already have an account? Sign in',
    'auth.newAccount': 'New here? Create an account',
    'auth.forgot': 'Forgot password?',
  };

  // match every english key with simplified chinese text
  static const _zh = <String, String>{
    'language': '语言',
    'english': 'English',
    'chinese': '简体中文',
    'home': '首页',
    'expenses': '支出',
    'convert': '换算',
    'settings': '设置',
    'signIn': '登录',
    'profile': '账户',
    'addExpense': '添加支出',
    'retryTransfer': '重试传输',
    'transferFailed': '访客支出传输失败，请保持应用开启并重试',
    'transferSaving': '正在将 {count} 笔访客支出保存到您的账户…',
    'home.title': '无论去哪里，都能掌握每一笔钱',
    'home.subtitle': '清楚了解本月的收支情况',
    'home.spent': '本月已支出',
    'home.expenseCount': '{count} 笔支出',
    'home.expense': '笔支出',
    'home.expenses': '笔支出',
    'home.loadingSpending': '正在加载本月支出',
    'home.spendingError': '无法加载本月支出',
    'home.retrySpending': '重试加载支出',
    'home.noExpenses': '本月暂无支出',
    'home.monthlyBudget': '每月预算',
    'home.editBudget': '编辑预算',
    'home.loadingBudget': '正在加载每月预算',
    'home.budgetError': '无法加载预算',
    'home.retryBudget': '重试加载预算',
    'home.noBudget': '尚未设置每月预算',
    'home.setBudget': '设置预算',
    'home.overBudget': '超出预算',
    'home.remaining': '剩余',
    'home.remainingUnavailable': '支出加载完成后将显示剩余金额',
    'home.categories': '分类支出',
    'home.categorySubtitle': '本月美元支出占比',
    'home.loadingCategories': '正在加载分类支出',
    'home.categoryError': '无法加载分类支出',
    'home.retryCategories': '重试加载分类',
    'home.viewExpenses': '查看支出',
    'home.converter': '货币换算',
    'monthly.title': '本月支出',
    'monthly.categoryTitle': '{category}支出',
    'monthly.clearFilter': '清除分类筛选',
    'monthly.empty': '本月暂无支出',
    'monthly.emptyCategory': '本月暂无{category}支出',
    'settings.title': '为你的目标留出空间',
    'settings.guest': '访客模式',
    'settings.guestNote': '访客支出仅临时保存，登录后会转移到账户',
    'settings.tagline': 'Pockit · 无论去哪里，都能掌握每一笔钱',
    'settings.budget': '每月预算',
    'settings.budgetHelp': '设置每月美元支出上限',
    'settings.loadingBudget': '正在加载预算',
    'settings.retryBudgetLoad': '重试加载预算',
    'settings.noBudget': '尚未设置预算',
    'settings.currentBudget': '当前预算：{amount} USD',
    'settings.budgetAmount': '预算金额',
    'settings.saveBudget': '保存预算',
    'settings.savingBudget': '正在保存…需要网络连接',
    'settings.retryBudgetSave': '重试保存预算',
    'settings.guestBudgetSaving': '正在将访客预算保存到账户…',
    'settings.retryBudgetTransfer': '重试预算传输',
    'settings.defaultCurrency': '默认货币',
    'settings.newExpenses': '新支出',
    'settings.loadingCurrency': '正在加载默认货币',
    'settings.retryCurrencyLoad': '重试加载货币',
    'settings.retryCurrencySave': '重试保存货币',
    'settings.savingCurrency': '正在保存默认货币',
    'settings.customCategories': '自定义分类',
    'settings.categoryLimit': '最多可添加 10 个分类',
    'settings.loadingCategories': '正在加载自定义分类',
    'settings.retryCategoryLoad': '重试加载分类',
    'settings.categoryName': '分类名称',
    'settings.addCategory': '添加分类',
    'settings.noCustomCategories': '暂无自定义分类',
    'settings.removeCategory': '删除{category}',
    'settings.savingCategories': '正在保存自定义分类',
    'settings.retryCategorySave': '重试保存分类',
    'category.Housing': '住房',
    'category.Groceries': '杂货',
    'category.Dining': '餐饮',
    'category.Transportation': '交通',
    'category.Bills': '账单',
    'category.Subscriptions': '订阅',
    'category.Shopping': '购物',
    'category.Entertainment': '娱乐',
    'category.Travel': '旅行',
    'category.Health': '医疗',
    'category.Education': '教育',
    'category.Other': '其他',
    'category.all': '所有分类',
    'category.empty': '本月暂无支出',
    'category.label': '分类',
    'previousMonth': '上个月',
    'nextMonth': '下个月',
    'thisMonth': '本月',
    'chooseMonthYear': '选择月份和年份',
    'month': '月份',
    'year': '年份',
    'cancel': '取消',
    'done': '完成',
    'delete': '删除',
    'retry': '重试',
    'expenses.title': '每一笔消费，都清清楚楚',
    'expenses.subtitle': '保留原始货币，并显示统一的美元金额',
    'expenses.deleteTitle': '删除这笔支出？',
    'expenses.deleted': '支出已删除',
    'expenses.deleteError': '无法删除，请重试',
    'expenses.undo': '撤销',
    'expenses.restoreError': '无法恢复，请重试',
    'expenses.rateDate': '汇率日期：{date}',
    'expenses.retryLoad': '重试加载支出',
    'expenses.empty': '暂无支出，添加第一笔消费吧',
    'expenses.emptyMonth': '本月暂无支出',
    'expenses.emptyCategory': '此分类暂无支出',
    'expenseForm.edit': '编辑支出',
    'expenseForm.amount': '支出金额',
    'expenseForm.currency': '货币',
    'expenseForm.date': '日期：{date}',
    'expenseForm.description': '说明（选填）',
    'expenseForm.rateHelp': '外币金额使用最新每日汇率，保存后的美元金额不会改变',
    'expenseForm.savedRate': '已保存：{amount} USD · 汇率日期 {date}',
    'expenseForm.saveError': '无法保存，请重试',
    'expenseForm.saving': '正在保存…需要网络连接',
    'expenseForm.save': '保存支出',
    'converter.title': '探索世界的更多可能',
    'converter.subtitle': '出发前先查看货币汇率',
    'converter.amount': '金额',
    'converter.amountHint': '输入金额',
    'converter.from': '从',
    'converter.to': '到',
    'converter.swap': '交换货币',
    'converter.conversion': '换算结果',
    'converter.refresh': '刷新汇率',
    'converter.fetching': '正在获取汇率',
    'converter.enterAmount': '输入金额',
    'converter.checkAmount': '请检查上方金额',
    'converter.noExchange': '无需换算',
    'converter.addExpense': '添加为支出',
    'converter.note': 'Frankfurter 汇率可能与银行汇率不同',
    'account.title': '账户',
    'account.syncing': '正在同步更改',
    'account.syncIssue': '同步需要处理',
    'account.syncOn': '云端同步已开启',
    'account.savedCount': '已保存 {count} 笔支出',
    'account.signingOut': '正在退出…',
    'account.signOut': '退出登录',
    'account.signOutTitle': '退出登录？',
    'account.signOutSyncing': '更改仍在同步，仍要退出吗？',
    'account.signOutQuestion': '退出此账户？',
    'auth.title': '您的账户',
    'auth.registerGreeting': '欢迎加入',
    'auth.signInGreeting': '欢迎回来',
    'auth.tagline': '无论去哪里，都能掌握每一笔钱',
    'auth.email': '电子邮箱',
    'auth.password': '密码',
    'auth.emailError': '请输入有效的电子邮箱',
    'auth.passwordError': '请输入密码',
    'auth.passwordLength': '密码至少需要 6 个字符',
    'auth.showPassword': '显示密码',
    'auth.hidePassword': '隐藏密码',
    'auth.wait': '请稍候…',
    'auth.create': '创建账户',
    'auth.signIn': '登录',
    'auth.or': '或',
    'auth.google': '使用 Google 继续',
    'auth.haveAccount': '已有账户？登录',
    'auth.newAccount': '新用户？创建账户',
    'auth.forgot': '忘记密码？',
  };

  // translate errors and feedback created by viewmodels
  static const _zhMessages = <String, String>{
    'Couldn’t load cloud expenses. Check your connection and Firestore access rules, then retry.':
        '无法加载云端支出，请检查网络和 Firestore 权限后重试',
    'Couldn’t load the exchange rate. Check your connection and retry.':
        '无法加载汇率，请检查网络后重试',
    'Couldn’t load your budget. Check your connection and retry.':
        '无法加载预算，请检查网络后重试',
    'Couldn’t load your preferred currency. Check your connection and retry.':
        '无法加载默认货币，请检查网络后重试',
    'Couldn’t load custom categories. Check your connection and retry.':
        '无法加载自定义分类，请检查网络后重试',
    'Couldn’t save your budget. Check your connection and retry.':
        '无法保存预算，请检查网络后重试',
    'Couldn’t save your preferred currency. Check your connection and retry.':
        '无法保存默认货币，请检查网络后重试',
    'Couldn’t save categories. Check your connection and retry.':
        '无法保存分类，请检查网络后重试',
    'Couldn’t complete that action. Please retry.': '无法完成操作，请重试',
    'Couldn’t restore your session. Please retry.': '无法恢复登录状态，请重试',
    'Enter a positive number, such as 25.50.': '请输入大于零的金额，例如 25.50',
    'Monthly budget saved': '每月预算已保存',
    'Budget set for this session': '本次使用的预算已设置',
    'Preferred currency saved': '默认货币已保存',
    'Preferred currency set for this session': '本次使用的默认货币已设置',
    'Category added': '分类已添加',
    'Category removed': '分类已删除',
    'Categories saved': '分类已保存',
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  // load the text bundle for the locale selected by material app
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// keep translated lookups short inside widgets
extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
