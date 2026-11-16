import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/budget_settings_card.dart';
import '../widgets/preferred_currency_card.dart';

// show budget and default currency settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    // explain guest storage without requiring an account
    if (auth.state.account == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Make room for your goals.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const Text('Guest mode'),
          const SizedBox(height: 8),
          const Text(
            'Guest expenses are temporary and transfer when you sign in.',
          ),
          const SizedBox(height: 24),
          const BudgetSettingsCard(guest: true),
          // keep guest preferences in memory only
          const PreferredCurrencyCard(),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Make room for your goals.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        const BudgetSettingsCard(guest: false),
        // save signed in preferences to firestore
        const PreferredCurrencyCard(),
        const SizedBox(height: 16),
        const Text('Pockit · Your money, wherever you go.'),
      ],
    );
  }
}
