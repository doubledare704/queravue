import 'dart:convert';

import '../../documents/domain/models.dart';

/// A `$jsonSchema` validator inferred from sampled fields: each field's
/// types, and `required` for fields every sampled document had. `_id` is
/// left out because the server always adds it.
String starterValidator(List<FieldStat> fields) {
  final properties = <String, Object>{};
  final required = <String>[];
  for (final f in fields) {
    if (f.name == '_id') continue;
    final types = f.types;
    if (types.isNotEmpty) {
      properties[f.name] = {
        'bsonType': types.length == 1 ? types.single : types,
      };
    } else {
      properties[f.name] = <String, Object>{};
    }
    if (f.frequency >= 1) required.add(f.name);
  }
  final schema = <String, Object>{
    'bsonType': 'object',
    if (required.isNotEmpty) 'required': required,
    if (properties.isNotEmpty) 'properties': properties,
  };
  return const JsonEncoder.withIndent('  ').convert({r'$jsonSchema': schema});
}
