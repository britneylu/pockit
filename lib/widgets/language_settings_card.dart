import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../viewmodels/locale_viewmodel.dart';

// let users switch the interface language at any time
class LanguageSettingsCard extends StatelessWidget {
  const LanguageSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // highlight the language currently used by material app
    final locale = Localizations.localeOf(context).languageCode;
    final text = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text.text('language'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<String>(
              key: const Key('languageSelector'),
              segments: [
                const ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'zh', label: Text(text.text('chinese'))),
              ],
              selected: {locale == 'zh' ? 'zh' : 'en'},
              // send the selected language to persistent app state
              onSelectionChanged: (selection) => context
                  .read<LocaleViewModel>()
                  .select(Locale(selection.first)),
            ),
          ],
        ),
      ),
    );
  }
}
