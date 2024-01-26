import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ethereum/src/utils/utils.dart';

void main() {
  test('utils_splitPath', () {
    final paths = splitPath("44'/60'/0'/0/0");
    expect(paths.join(','), '2147483692,2147483708,2147483648,0,0');
  });
}
