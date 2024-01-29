import 'dart:typed_data';

List<int> arrayifyInteger(int value) {
  final result = <int>[];
  while (value != 0) {
    result.insert(0, value & 0xff);
    value >>= 8;
  }
  return result;
}

int unarrayifyInteger(Uint8List data, int offset, int length) {
  var result = 0;
  for (var i = 0; i < length; i++) {
    result = (result * 256) + data[offset + i];
  }
  return result;
}

List<int> _encode(dynamic object) {
  if (object is List) {
    var payload = <int>[];
    for (var child in object) {
      payload.addAll(_encode(child));
    }

    if (payload.length <= 55) {
      payload.insert(0, 0xc0 + payload.length);
      return payload;
    }

    final length = arrayifyInteger(payload.length);
    length.insert(0, 0xf7 + length.length);

    return [...length, ...payload];
  }

  if (!(object is Uint8List)) {
    throw ArgumentError("RLP object must be BytesLike");
  }

  final data = object.toList();

  if (data.length == 1 && data[0] <= 0x7f) {
    return data;
  } else if (data.length <= 55) {
    data.insert(0, 0x80 + data.length);
    return data;
  }

  final length = arrayifyInteger(data.length);
  length.insert(0, 0xb7 + length.length);

  return [...length, ...data];
}

Uint8List encode(dynamic object) {
  return Uint8List.fromList(_encode(object));
}

class Decoded {
  dynamic result;
  int consumed;

  Decoded(this.result, this.consumed);
}

Decoded _decodeChildren(
    Uint8List data, int offset, int childOffset, int length) {
  final result = [];

  while (childOffset < offset + 1 + length) {
    final decoded = _decode(data, childOffset);
    result.add(decoded.result);

    childOffset += decoded.consumed;
    if (childOffset > offset + 1 + length) {
      throw ArgumentError("child data too short");
    }
  }

  return Decoded(result, 1 + length);
}

Decoded _decode(Uint8List data, int offset) {
  if (data.isEmpty) {
    throw ArgumentError("data too short");
  }

  if (data[offset] >= 0xf8) {
    final lengthLength = data[offset] - 0xf7;
    if (offset + 1 + lengthLength > data.length) {
      throw ArgumentError("data short segment too short");
    }

    final length = unarrayifyInteger(data, offset + 1, lengthLength);
    if (offset + 1 + lengthLength + length > data.length) {
      throw ArgumentError("data long segment too short");
    }

    return _decodeChildren(
        data, offset, offset + 1 + lengthLength, lengthLength + length);
  } else if (data[offset] >= 0xc0) {
    final length = data[offset] - 0xc0;
    if (offset + 1 + length > data.length) {
      throw ArgumentError("data array too short");
    }

    return _decodeChildren(data, offset, offset + 1, length);
  } else if (data[offset] >= 0xb8) {
    final lengthLength = data[offset] - 0xb7;
    if (offset + 1 + lengthLength > data.length) {
      throw ArgumentError("data array too short");
    }

    final length = unarrayifyInteger(data, offset + 1, lengthLength);
    if (offset + 1 + lengthLength + length > data.length) {
      throw ArgumentError("data array too short");
    }

    final result = data.sublist(
        offset + 1 + lengthLength, offset + 1 + lengthLength + length);
    return Decoded(result, 1 + lengthLength + length);
  } else if (data[offset] >= 0x80) {
    final length = data[offset] - 0x80;
    if (offset + 1 + length > data.length) {
      throw ArgumentError("data too short");
    }

    final result = data.sublist(offset + 1, offset + 1 + length);
    return Decoded(result, 1 + length);
  }

  return Decoded([data[offset]], 1);
}

dynamic decode(Uint8List data) {
  final decoded = _decode(data, 0);
  if (decoded.consumed != data.length) {
    throw ArgumentError("invalid rlp data");
  }
  return decoded.result;
}
