import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_test/api_mcc_data.dart';

void main() {
  group('amount parsing', () {
    test('parses integers and integer strings', () {
      expect(_ticker(amount: 12).amount, 12);
      expect(_ticker(amount: '34').amount, 34);
      expect(_tickerItem(amount: 12).amount, 12);
      expect(_tickerItem(amount: '34').amount, 34);
    });

    test('uses zero for empty strings and null', () {
      expect(_ticker(amount: '').amount, 0);
      expect(_ticker(amount: null).amount, 0);
      expect(_tickerItem(amount: '').amount, 0);
      expect(_tickerItem(amount: null).amount, 0);
    });
  });
}

Ticker _ticker({required Object? amount}) => Ticker.fromJson({
      'id': 'ticker',
      'type': 'ticker',
      'ticker_type': 1,
      'name': 'Ticker',
      'amount': amount,
      'url': '',
    });

TickerItem _tickerItem({required Object? amount}) => TickerItem.fromJson({
      'id': 'ticker-item',
      'region_id': 'region',
      'type': 'ticker',
      'name': 'Ticker item',
      'amount': amount,
    });
