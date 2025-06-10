import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ethereum/src/utils/transaction_handler.dart';
import 'package:ledger_ethereum/src/utils/utils.dart';
import 'package:web3dart_avacus/crypto.dart';
import 'package:web3dart_avacus/web3dart_avacus.dart';

void main() {
  test('utils_splitPath', () {
    final paths = splitPath("44'/60'/0'/0/0");
    expect(paths.join(','), '2147483692,2147483708,2147483648,0,0');
  });
  test('transaction_handler_decodeTx_message', () {
    final decodedTx = TransactionHandler.decodeTx(hexToBytes(
        '02ef0306843b9aca008504a817c80082520894b2bb2b958afa2e96dab3f3ce7162b87daea39017872386f26fc1000080c0'));
    expect(bytesToHex(decodedTx.decodedTx.to, include0x: true),
        '0xb2bb2b958afa2e96dab3f3ce7162b87daea39017');
  });
  test('transaction_handler_decodeTx_tx', () {
    final tx = Transaction(
        to: EthereumAddress.fromHex(
            '0x0AE982e6C7e6e489C9b53e58eBEb2F7dF0615049'),
        value: EtherAmount.fromUnitAndValue(EtherUnit.wei, '0x9184e72a000'),
        maxGas: BigInt.parse('0x5208').toInt(),
        maxFeePerGas:
            EtherAmount.fromUnitAndValue(EtherUnit.wei, '0xe2300c4b8'),
        maxPriorityFeePerGas:
            EtherAmount.fromUnitAndValue(EtherUnit.wei, '0x826299e00'),
        nonce: 0,
        data: Uint8List.fromList(hexToBytes('0x')));
    final txBytes = TransactionHandler.encodeTx(tx, BigInt.from(137));
    final decodedTx = TransactionHandler.decodeTx(txBytes);
    expect(bytesToHex(decodedTx.decodedTx.to, include0x: true),
        '0x0AE982e6C7e6e489C9b53e58eBEb2F7dF0615049'.toLowerCase());
  });
}
