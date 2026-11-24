import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../l10n/app_localizations.dart';
import '../widgets/budget_settings_card.dart';
import '../widgets/custom_categories_card.dart';
import '../widgets/preferred_currency_card.dart';
import '../widgets/language_settings_card.dart';

// show budget and default currency settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final text = context.l10n;
    // explain guest storage without requiring an account
    if (auth.state.account == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            text.text('settings.title'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(text.text('settings.guest')),
          const SizedBox(height: 8),
          Text(text.text('settings.guestNote')),
          const SizedBox(height: 24),
          const BudgetSettingsCard(guest: true),
          // keep guest preferences in memory only
          const PreferredCurrencyCard(),
          const LanguageSettingsCard(),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          text.text('settings.title'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        const BudgetSettingsCard(guest: false),
        // save signed in preferences to firestore
        const PreferredCurrencyCard(),
        // custom categories are available only for signed in accounts
        const CustomCategoriesCard(),
        const LanguageSettingsCard(),
        Text(text.text('settings.tagline')),
      ],
    );
  }
}
