import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'finance_quotes.dart';

const _lastIndexKey = 'mp_last_splash_quote_index';

/// Picks a random quote for this launch, guaranteed different from
/// whichever one was shown last launch (avoids the "feels random but
/// showed the same one twice in a row" complaint with a 177-quote pool).
///
/// Entirely local — `financeQuotes` is bundled in the app binary, so this
/// never depends on network access. There is no remote quote source to
/// "fall back" from; bundled-local is the only source, by design, so it
/// always works offline.
Future<FinanceQuote> pickSplashQuote() async {
  final prefs = await SharedPreferences.getInstance();
  final lastIndex = prefs.getInt(_lastIndexKey);

  final random = Random();
  var index = random.nextInt(financeQuotes.length);
  if (financeQuotes.length > 1 && index == lastIndex) {
    index = (index + 1 + random.nextInt(financeQuotes.length - 1)) % financeQuotes.length;
  }

  await prefs.setInt(_lastIndexKey, index);
  return financeQuotes[index];
}
