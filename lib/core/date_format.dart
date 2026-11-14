// format dates for display without changing stored timestamps
String formatUsDate(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().padLeft(4, '0')}';
