import 'dart:typed_data';

import 'package:ledger_ethereum/src/operations/ethereum_transaction_operation.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:web3dart/crypto.dart';

import './model/account.dart';
import './model/signature.dart';
import './operations/ethereum_personal_message_operation.dart';
import 'operations/ethereum_public_key_operation.dart';
import 'utils/utils.dart';

class EthereumAppLedger extends LedgerApp {
  final int accountIndex;
  final LedgerTransformer? transformer;

  EthereumAppLedger(super.ledger, {this.accountIndex = 0, this.transformer});

  @override
  Future<List<String>> getAccounts(LedgerDevice device) async {
    final account = await ledger.sendOperation<Account>(
      device,
      EthereumPublicKeyOperation(accountIndex: accountIndex),
      transformer: transformer,
    );
    return [account.publicKey];
  }

  @override
  Future<Uint8List> signPersonalMessage(
      LedgerDevice device, Uint8List message) async {
    final signature = await ledger.sendOperation<Signature>(
      device,
      EthereumPersonalMessageOperation(
          accountIndex: accountIndex, message: message),
      transformer: transformer,
    );
    final r = padUint8ListTo32(hexToBytes(signature.r));
    final s = padUint8ListTo32(hexToBytes(signature.s));
    final v = unsignedIntToBytes(BigInt.from(signature.v));
    return uint8ListFromList(r + s + v);
  }

  @override
  Future<Uint8List> signTransaction(
      LedgerDevice device, Uint8List transaction) async {
    final signature = await ledger.sendOperation<Map<String, String>>(
      device,
      EthereumTransactionOperation(
          accountIndex: accountIndex, transaction: transaction),
      transformer: transformer,
    );
    final r = padUint8ListTo32(hexToBytes(signature['r']!));
    final s = padUint8ListTo32(hexToBytes(signature['s']!));
    final v = hexToBytes(signature['v']!);
    return uint8ListFromList(r + s + v);
  }

  @override
  Future getVersion(LedgerDevice device) {
    // TODO: implement getVersion
    throw UnimplementedError();
  }

  @override
  Future<List<Uint8List>> signTransactions(
      LedgerDevice device, List<Uint8List> transactions) {
    // TODO: implement signTransactions
    throw UnimplementedError();
  }
}
