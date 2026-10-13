// lib/helpers/toon.helper.dart

/// Minimal TOON (Token-Oriented Object Notation) encoder for LLM prompts.
///
/// TOON is a compact, schema-explicit format for LLM input
/// (spec: https://github.com/toon-format/toon): objects use indentation,
/// uniform arrays of objects collapse into CSV-style tables
/// (`key[N]{a,b,c}:` + one row per item), and scalars stay bare unless they
/// would be ambiguous. It spends 30-60% fewer tokens than JSON on the
/// tabular payloads we hand the model (molecule digests etc.).
///
/// The encoder is deliberately small and deterministic: maps, lists of
/// uniform maps (tables), lists of scalars, and flat list items. Values in
/// tables must be scalars (String/num/bool/null); nested values fall back to
/// the expanded `- item` form.
class Toon {
  const Toon._();

  static const String _indent = '  ';

  /// Encodes [value] (Map / List / scalar) as a TOON document.
  static String encode(Object? value) {
    if (value is Map) return _object(value, 0);
    if (value is List) return _array('value', value, 0);
    return _scalar(value);
  }

  // ── Objects ──────────────────────────────────────────────────────────
  static String _object(Map<dynamic, dynamic> map, int depth) {
    final pad = _indent * depth;
    final lines = <String>[];
    map.forEach((key, value) {
      final k = _string(key.toString());
      if (value is List) {
        lines.add(_array(k, value, depth));
      } else if (value is Map) {
        lines.add('$pad$k:');
        if (value.isNotEmpty) {
          lines.add(_object(value, depth + 1));
        }
      } else {
        lines.add('$pad$k: ${_scalar(value)}');
      }
    });
    return lines.join('\n');
  }

  // ── Arrays ───────────────────────────────────────────────────────────
  static String _array(String key, List<dynamic> items, int depth) {
    final pad = _indent * depth;
    if (items.isEmpty) return '$pad$key[0]:';

    // Array of scalars -> inline comma-separated form.
    if (items.every((item) => item is! Map && item is! List)) {
      return '$pad$key[${items.length}]: ${items.map(_cell).join(',')}';
    }

    final maps = <Map<dynamic, dynamic>>[];
    for (final item in items) {
      if (item is! Map) return _expanded(key, items, depth);
      maps.add(item);
    }
    if (!_uniform(maps)) return _expanded(key, items, depth);

    // Uniform array of flat maps -> CSV-style table.
    final keys = maps.first.keys.toList();
    final buffer = StringBuffer(
      '$pad$key[${items.length}]'
      '{${keys.map((k) => _string(k.toString())).join(',')}}:',
    );
    for (final row in maps) {
      buffer.write(
        '\n$pad$_indent'
        '${[for (final k in keys) _cell(row[k])].join(',')}',
      );
    }
    return buffer.toString();
  }

  /// Non-uniform arrays / scalar arrays render in the expanded form.
  static String _expanded(String key, List<dynamic> items, int depth) {
    final pad = _indent * depth;
    final buffer = StringBuffer('$pad$key[${items.length}]:');
    for (final item in items) {
      if (item is Map && item.isNotEmpty) {
        final entries = item.entries.toList();
        final first = entries.first;
        buffer.write(
          '\n$pad- ${_string(first.key.toString())}: '
          '${_inline(first.value, depth + 1)}',
        );
        for (final entry in entries.skip(1)) {
          buffer.write(
            '\n$pad$_indent${_string(entry.key.toString())}: '
            '${_inline(entry.value, depth + 1)}',
          );
        }
      } else {
        buffer.write('\n$pad- ${_inline(item, depth + 1)}');
      }
    }
    return buffer.toString();
  }

  static String _inline(Object? value, int depth) {
    if (value is Map && value.isNotEmpty) {
      return '\n${_object(value, depth + 1)}';
    }
    if (value is List && value.isNotEmpty) {
      return '\n${_array('items', value, depth + 1)}';
    }
    return _scalar(value);
  }

  // ── Scalars ──────────────────────────────────────────────────────────
  static bool _uniform(List<Map<dynamic, dynamic>> maps) {
    if (maps.isEmpty) return false;
    final keys = maps.first.keys.toList();
    for (final map in maps) {
      if (map.isEmpty || map.length != keys.length) return false;
      for (final key in keys) {
        if (!map.containsKey(key)) return false;
        final value = map[key];
        if (value is Map || value is List) return false;
      }
    }
    return true;
  }

  static String _cell(Object? value) => _scalar(value);

  static String _scalar(Object? value) {
    if (value == null) return 'null';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return value.toString();
    return _string(value.toString());
  }

  static final RegExp _needsQuotes = RegExp(r'[,:\[\]{}"\n\r\t]|^- ');

  static String _string(String value) {
    final bare =
        value.isNotEmpty &&
        value.trim() == value &&
        value != 'true' &&
        value != 'false' &&
        value != 'null' &&
        num.tryParse(value) == null &&
        !value.contains(_needsQuotes);
    if (bare) return value;
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }
}
