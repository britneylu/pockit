import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/expenses_viewmodel.dart';

// keep account details and sign out controls outside settings
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final budget = context.watch<BudgetViewModel>().state;
    final expenses = context.watch<ExpensesViewModel>().state;
    // include every write that may still be syncing
    final saving =
        expenses.saving ||
        budget.saving ||
        budget.currencySaving ||
        budget.transferring;
    // show when cloud data needs another attempt
    final syncIssue =
        expenses.error != null ||
        budget.loadError != null ||
        budget.saveError != null ||
        budget.currencyLoadError != null ||
        budget.currencySaveError != null ||
        budget.transferError != null;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 34,
                    child: Icon(Icons.person_outline, size: 34),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  auth.state.account?.email ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                // summarize cloud storage without adding account settings here
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Semantics(
                      liveRegion: saving || syncIssue,
                      child: Row(
                        children: [
                          Icon(
                            saving
                                ? Icons.sync
                                : syncIssue
                                ? Icons.cloud_off_outlined
                                : Icons.cloud_done_outlined,
                            color: syncIssue
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  saving
                                      ? 'Syncing changes'
                                      : syncIssue
                                      ? 'Sync needs attention'
                                      : 'Cloud sync on',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${expenses.expenses.length} ${expenses.expenses.length == 1 ? 'expense' : 'expenses'} saved',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (auth.state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        auth.state.error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: auth.state.busy
                      ? null
                      : () => _confirmSignOut(context, auth, saving),
                  icon: const Icon(Icons.logout),
                  label: Text(auth.state.busy ? 'Signing out…' : 'Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // confirm before ending the current account session
  Future<void> _confirmSignOut(
    BuildContext context,
    AuthViewModel auth,
    bool saving,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          saving
              ? 'Your changes are still syncing. Sign out anyway?'
              : 'Sign out of this account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.signOut();
  }
}
