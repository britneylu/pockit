import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'repositories/budget_repository.dart';
import 'viewmodels/budget_viewmodel.dart';
import 'services/currency_service.dart';
import 'viewmodels/converter_viewmodel.dart';
import 'views/converter_screen.dart';
import 'views/home_screen.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'views/expenses_screen.dart';
import 'views/expense_form.dart';
import 'repositories/expense_repository.dart';
import 'repositories/firestore_expense_repository.dart';
import 'viewmodels/guest_transfer_viewmodel.dart';
import 'services/auth_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth_screen.dart';
import 'views/account_screen.dart';
import 'views/settings_screen.dart';
import 'viewmodels/expenses_viewmodel.dart';
import 'viewmodels/locale_viewmodel.dart';

// create a separate expense repository for each account
typedef ExpenseRepositoryFactory = ExpenseRepository Function(String userId);

// provide authentication state to the whole app
class PockitApp extends StatelessWidget {
  const PockitApp({
    super.key,
    this.currencyService,
    this.authService,
    this.expenseRepositoryFactory,
    this.budgetRepositoryFactory,
  });
  final CurrencyService? currencyService;
  final AuthService? authService;
  final ExpenseRepositoryFactory? expenseRepositoryFactory;
  final BudgetRepository Function(String)? budgetRepositoryFactory;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(authService ?? FirebaseAuthService()),
      ),
      // load the saved interface language for every account
      ChangeNotifierProvider(create: (_) => LocaleViewModel()..load()),
      ChangeNotifierProvider(
        lazy: false,
        create: (context) => BudgetViewModel(
          context.read<AuthViewModel>(),
          budgetRepositoryFactory ?? (id) => FirestoreBudgetRepository(id),
        ),
      ),
      ChangeNotifierProvider(
        lazy: false,
        create: (context) => GuestTransferViewModel(
          context.read<AuthViewModel>(),
          expenseRepositoryFactory ??
              (id) => FirestoreExpenseRepository(userId: id),
        ),
      ),
    ],
    child: Consumer<AuthViewModel>(
      builder: (context, model, _) {
        final state = model.state;
        final account = state.account;
        // reset the workspace when the account changes
        return _AccountWorkspace(
          key: ValueKey(account == null ? 'guest' : 'account:${account.id}'),
          currencyService: currencyService ?? FrankfurterCurrencyService(),
          repositoryFactory:
              expenseRepositoryFactory ??
              (id) => FirestoreExpenseRepository(userId: id),
        );
      },
    ),
  );
}

// the account key destroys the previous navigator, viewmodels, and subscriptions
// on sign-out or account changes, including any open expense form
class _AccountWorkspace extends StatelessWidget {
  const _AccountWorkspace({
    super.key,
    required this.currencyService,
    required this.repositoryFactory,
  });
  final CurrencyService currencyService;
  final ExpenseRepositoryFactory repositoryFactory;
  @override
  Widget build(BuildContext context) {
    final account = context.read<AuthViewModel>().state.account;
    // rebuild material app whenever the language changes
    final locale = context.watch<LocaleViewModel>().locale;
    // use temporary guest storage or the signed in account repository
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConverterViewModel(currencyService),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpensesViewModel(
            account == null
                ? context.read<GuestTransferViewModel>().guestRepository
                : repositoryFactory(account.id),
            currencyService,
            // read the latest account categories during validation
            customCategories: () =>
                context.read<BudgetViewModel>().state.customCategories,
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardViewModel(
            context.read<ExpensesViewModel>(),
            context.read<BudgetViewModel>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Pockit',
        theme: appTheme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        // localize app text and built in flutter controls
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          ...GlobalMaterialLocalizations.delegates,
        ],
        debugShowCheckedModeBanner: false,
        home: const PockitShell(),
      ),
    );
  }
}

// keep the four main tabs in one navigation shell
class PockitShell extends StatefulWidget {
  const PockitShell({super.key});
  @override
  State<PockitShell> createState() => _PockitShellState();
}

class _PockitShellState extends State<PockitShell> {
  int _index = 0;
  // change tabs and fetch the first converter rate when needed
  void _select(int value) {
    setState(() => _index = value);
    final model = context.read<ConverterViewModel>();
    if (value == 2 && model.state.status == ConversionStatus.idle) {
      model.refresh();
    }
  }

  // open one shared form from any tab
  void _addExpense() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ExpenseForm()),
    );
  }

  // map four page indexes around the center add action
  int get _bottomIndex => _index < 2 ? _index : _index + 1;

  // open the form when the middle slot is selected
  void _selectBottom(int value) {
    if (value == 2) {
      _addExpense();
      return;
    }
    _select(value < 2 ? value : value - 1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final transfer = context.watch<GuestTransferViewModel>();
    final text = context.l10n;
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        label: text.text('home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        label: text.text('expenses'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.currency_exchange),
        label: text.text('convert'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        label: text.text('settings'),
      ),
    ];
    // leave the middle mobile slot for the global add action
    final bottomDestinations = [
      destinations[0],
      destinations[1],
      const NavigationDestination(icon: _AddNavigationIcon(), label: ''),
      destinations[2],
      destinations[3],
    ];
    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          // preserve each tab while another tab is visible
          child: IndexedStack(
            index: _index,
            children: [
              HomeScreen(
                onExpenses: () => _select(1),
                onSettings: () => _select(3),
                onConvert: () => _select(2),
              ),
              const ExpensesScreen(),
              const ConverterScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // use a navigation rail when the window is wide enough
        final wide = constraints.maxWidth >= 840;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'pockit.',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            centerTitle: false,
            actions: [
              if (auth.state.account == null)
                TextButton(
                  key: const Key('signInButton'),
                  onPressed: auth.state.initializing
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AuthScreen(),
                          ),
                        ),
                  child: Text(text.text('signIn')),
                )
              else
                IconButton(
                  key: const Key('profileButton'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountScreen(),
                    ),
                  ),
                  tooltip: text.text('profile'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              if (transfer.pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        Text(
                          transfer.failed
                              ? text.text('transferFailed')
                              : text.text('transferSaving', {
                                  'count': transfer.pendingCount,
                                }),
                        ),
                        if (transfer.failed)
                          TextButton(
                            onPressed: transfer.retry,
                            child: Text(text.text('retryTransfer')),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: wide
                    ? Row(
                        children: [
                          NavigationRail(
                            selectedIndex: _index,
                            onDestinationSelected: _select,
                            labelType: NavigationRailLabelType.all,
                            leading: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FloatingActionButton.small(
                                onPressed: _addExpense,
                                tooltip: text.text('addExpense'),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimary,
                                child: const Icon(Icons.add),
                              ),
                            ),
                            destinations: destinations
                                .map(
                                  (d) => NavigationRailDestination(
                                    icon: d.icon,
                                    label: Text(d.label),
                                  ),
                                )
                                .toList(),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: content),
                        ],
                      )
                    : content,
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _bottomIndex,
                  onDestinationSelected: _selectBottom,
                  destinations: bottomDestinations,
                ),
        );
      },
    );
  }
}

// align the add action with the other navigation icons
class _AddNavigationIcon extends StatelessWidget {
  const _AddNavigationIcon();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = context.l10n;
    return Tooltip(
      message: text.text('addExpense'),
      child: Transform.translate(
        offset: const Offset(0, 8),
        child: Material(
          color: colors.primary,
          elevation: 3,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 46,
            child: Icon(Icons.add, size: 26, color: colors.onPrimary),
          ),
        ),
      ),
    );
  }
}
