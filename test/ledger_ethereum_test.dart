import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ethereum/src/utils/transaction_decoder.dart';
import 'package:ledger_ethereum/src/utils/utils.dart';
import 'package:web3dart/crypto.dart';

void main() {
  test('utils_splitPath', () {
    final paths = splitPath("44'/60'/0'/0/0");
    expect(paths.join(','), '2147483692,2147483708,2147483648,0,0');
  });
  test('transaction_decoder_decodeTxInfo', () {
    final decodedTx = TransactionDecoder.decodeTxInfo(hexToBytes(
        '02ef0306843b9aca008504a817c80082520894b2bb2b958afa2e96dab3f3ce7162b87daea39017872386f26fc1000080c0'));
    expect(bytesToHex(decodedTx.decodedTx.to, include0x: true),
        '0xb2bb2b958afa2e96dab3f3ce7162b87daea39017');
  });
}
