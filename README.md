# ledger_ethereum

A Flutter Package to support communicate between Ledger Nano X device and EVM compatible chains apps

Fully support at [Avacus](https://avacus.cc) so you can have the best experience.

Feel free to use and don't hesitate to raise issue if there are.

## Getting Started

### Installation

Install the latest version of this package via pub.dev:

```yaml
ledger_ethereum: ^latest-version
```

For integration with the Ledger Flutter package, check out the documentation [here](https://pub.dev/packages/ledger_flutter).

### Setup

Create a new instance of an `EthereumLedgerApp` and pass an instance of your `Ledger` object.

```dart
final app = EthereumLedgerApp(ledger);
```

## Usage

### Get accounts

```dart
final accounts = await app.getAccounts(device);
```

### Sign personal message

```dart
final signature = await app.signPersonalMessage(
    device,
    messageInBytes,
);
```

### Sign typed data

```dart
final signature = await app.signEIP712Message(
    device,
    messageInJson,
);
```

### Sign transaction

```dart
final transactionInBytes = TransactionHandler.encodeTx(transaction, chainId);
final signature = await app.signTransaction(
    device,
    transactionInBytes,
);
```