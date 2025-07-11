import 'dart:typed_data';

import 'package:ledger/ledger.dart';

abstract class BaseEthereumLedgerApp extends LedgerApp {
  BaseEthereumLedgerApp(super.ledger);

  @override
  Future<List<String>> getAccounts(LedgerDevice device) {
    throw UnimplementedError();
  }

  @override
  Future getVersion(LedgerDevice device) {
    throw UnimplementedError();
  }

  @override
  Future<List<Uint8List>> signTransactions(
      LedgerDevice device, List<Uint8List> transactions) {
    throw UnimplementedError();
  }

  Future<Uint8List> signEIP712HashedMessage(
      {required LedgerDevice device,
      required Uint8List domainSeparator,
      required Uint8List hashStructMessage});

  Future<Uint8List> signEIP712Message(LedgerDevice device, String jsonMessage);

  Future<Uint8List> signPersonalMessage(LedgerDevice device, Uint8List message);
}
