import 'package:flutter/material.dart';

import '../models/currency.dart';

// show currencies with a compact sign code and name layout
class CurrencyDropdown extends StatelessWidget {
  const CurrencyDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.fieldKey,
  });

  final String label;
  final Currency value;
  final ValueChanged<Currency>? onChanged;
  final Key? fieldKey;

  // place the current choice first and sort the remaining codes
  static List<Currency> orderedCurrencies(Currency selected) {
    final remaining =
        Currency.values
            .where(
              (currency) => currency != selected && currency != Currency.usd,
            )
            .toList()
          ..sort((a, b) => a.code.compareTo(b.code));
    return [selected, if (selected != Currency.usd) Currency.usd, ...remaining];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DropdownButtonFormField<Currency>(
      // rebuild the field when its selected currency changes
      key: fieldKey ?? ValueKey('$label-${value.code}'),
      initialValue: value,
      isExpanded: true,
      itemHeight: 52,
      menuMaxHeight: 320,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      ),
      items: orderedCurrencies(value)
          .map(
            (currency) => DropdownMenuItem(
              value: currency,
              child: Row(
                children: [
                  // keep every currency sign aligned in the menu
                  SizedBox(
                    width: 28,
                    child: Text(
                      currency.symbol,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${currency.code} · ${currency.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged == null
          ? null
          : (currency) {
              if (currency != null) onChanged!(currency);
            },
    );
  }
}
