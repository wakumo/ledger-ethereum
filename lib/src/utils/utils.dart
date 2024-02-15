import 'dart:typed_data';

List<int> splitPath(String path) {
  List<int> result = [];
  List<String> components = path.split("/");

  for (var element in components) {
    int number = int.tryParse(element.replaceAll("'", "")) ?? 0;

    if (element.length > 1 && element[element.length - 1] == "'") {
      number += 0x80000000;
    }

    result.add(number);
  }

  return result;
}

Uint8List padUint8ListTo32(Uint8List data) {
  assert(data.length <= 32);
  if (data.length == 32) return data;
  return Uint8List(32)..setRange(32 - data.length, 32, data);
}

Uint8List uint8ListFromList(List<int> data) {
  if (data is Uint8List) return data;
  return Uint8List.fromList(data);
}
