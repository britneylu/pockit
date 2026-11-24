import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

// switch months with arrows or a direct month and year picker
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    required this.onSelected,
    required this.monthKey,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrent;
  final ValueChanged<DateTime> onSelected;
  final Key monthKey;

  // wait for the dialog and ignore a canceled selection
  Future<void> _chooseMonth(BuildContext context) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearDialog(initialMonth: month),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = context.l10n;
    final monthLabel = text.month(month);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: text.text('previousMonth'),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              // announce the month title as an interactive control
              child: Semantics(
                button: true,
                liveRegion: true,
                label: '$monthLabel, ${text.text('chooseMonthYear')}',
                child: Tooltip(
                  message: text.text('chooseMonthYear'),
                  child: InkWell(
                    onTap: () => _chooseMonth(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              monthLabel,
                              key: monthKey,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: text.text('nextMonth'),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        TextButton(onPressed: onCurrent, child: Text(text.text('thisMonth'))),
      ],
    );
  }
}

class _MonthYearDialog extends StatefulWidget {
  const _MonthYearDialog({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthYearDialog> createState() => _MonthYearDialogState();
}

class _MonthYearDialogState extends State<_MonthYearDialog> {
  late int _month;
  late int _year;
  late int _firstYear;
  late int _lastYear;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = widget.initialMonth.month;
    _year = widget.initialMonth.year;
    // include older years and a few future years
    _firstYear = math.min(2000, widget.initialMonth.year);
    _lastYear = math.max(now.year + 10, widget.initialMonth.year);
    // start both wheels on the month already shown on the screen
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _year - _firstYear,
    );
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = [for (var year = _firstYear; year <= _lastYear; year++) year];
    final text = context.l10n;
    final monthNames = [
      for (var month = 1; month <= 12; month++)
        text.isChinese
            ? '$month月'
            : text.month(DateTime(2000, month)).split(' ').first,
    ];
    return AlertDialog(
      title: Text(text.text('chooseMonthYear')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(text.text('month'), textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text(text.text('year'), textAlign: TextAlign.center),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // scroll month and year independently
            SizedBox(
              height: 190,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _monthController,
                      itemExtent: 40,
                      useMagnifier: true,
                      magnification: 1.08,
                      onSelectedItemChanged: (index) => _month = index + 1,
                      children: monthNames
                          .map((month) => Center(child: Text(month)))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: _yearController,
                      itemExtent: 40,
                      useMagnifier: true,
                      magnification: 1.08,
                      onSelectedItemChanged: (index) => _year = years[index],
                      children: years
                          .map((year) => Center(child: Text('$year')))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.text('cancel')),
        ),
        FilledButton(
          // return both wheel selections to the screen
          onPressed: () => Navigator.pop(context, DateTime(_year, _month)),
          child: Text(text.text('done')),
        ),
      ],
    );
  }
}
