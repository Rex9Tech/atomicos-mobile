// test/locales/translation_coverage_test.dart
//
// Guards against raw keys leaking into the UI: every `AppLocales.*.tr` /
// `.trParams` usage in lib/ must resolve to a key that exists in BOTH the
// en_US and my_MM translation blocks. (Two batches of entries were silently
// lost to crashed scripts before this test existed — testers saw
// 'create.import' etc. instead of text.)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every used AppLocales key exists in en_US and my_MM', () {
    final locSrc = File('lib/locales/app_locales.dart').readAsStringSync();
    final trSrc = File('lib/locales/app_translations.dart').readAsStringSync();

    // ---- parse classes: fields (name -> key value) + accessors ----
    final classRe = RegExp(r'class (\w+) \{');
    final classStarts = classRe.allMatches(locSrc).toList();
    final classes = <String, Map<String, Map<String, String>>>{};

    for (var i = 0; i < classStarts.length; i++) {
      final name = classStarts[i].group(1)!;
      final start = classStarts[i].end;
      final end = i + 1 < classStarts.length ? classStarts[i + 1].start : locSrc.length;
      final body = locSrc.substring(start, end);

      final fields = <String, String>{};
      for (final m in RegExp(r"(?:final|String get)\s+(\w+)\s*=>?\s*'([^']+)';")
          .allMatches(body)) {
        fields[m.group(1)!] = m.group(2)!;
      }
      final accessors = <String, String>{};
      for (final m in RegExp(
              r'(?:static const|final)\s+(\w+)\s*=\s*(?:const\s+)?(\w+)\(\);')
          .allMatches(body)) {
        accessors[m.group(1)!] = m.group(2)!;
      }
      classes[name] = {'fields': fields, 'accessors': accessors};
    }

    String? resolve(String path) {
      final segs = path.split('.');
      var cls = 'AppLocales';
      for (final seg in segs.sublist(0, segs.length - 1)) {
        final tgt = classes[cls]?['accessors']?[seg];
        if (tgt == null) return null;
        cls = tgt;
      }
      return classes[cls]?['fields']?[segs.last];
    }

    Set<String> blockKeys(String locale, int stop) {
      final start = trSrc.indexOf("'$locale': {");
      final body = trSrc.substring(start, stop);
      final keys = <String>{};
      for (final m in RegExp(r"AppLocales\.((?:\w+\.)+\w+)\s*:")
          .allMatches(body)) {
        final v = resolve(m.group(1)!);
        if (v != null) keys.add(v);
      }
      return keys;
    }

    final startMy = trSrc.indexOf("'my_MM': {");
    final enKeys = blockKeys('en_US', startMy);
    final myKeys = blockKeys('my_MM', trSrc.lastIndexOf('};'));
    expect(enKeys.length, greaterThan(300), reason: 'en block parsed');
    expect(myKeys.length, greaterThan(300), reason: 'my block parsed');

    // ---- every usage in lib/ ----
    final missingEn = <String>[];
    final missingMy = <String>[];
    final unresolved = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.replaceAll('\\', '/').contains('/locales/')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final m in RegExp(r'AppLocales\.((?:\w+\.)+\w+)\.(?:tr|trParams)\b')
            .allMatches(lines[i])) {
          final value = resolve(m.group(1)!);
          if (value == null) {
            unresolved.add('${entity.path}:${i + 1} -> ${m.group(1)}');
            continue;
          }
          if (!enKeys.contains(value)) {
            missingEn.add('$value  (${entity.path}:${i + 1})');
          }
          if (!myKeys.contains(value)) {
            missingMy.add('$value  (${entity.path}:${i + 1})');
          }
        }
      }
    }

    expect(
      unresolved,
      isEmpty,
      reason: 'fields that could not be resolved:\n${unresolved.join('\n')}',
    );
    expect(
      missingEn,
      isEmpty,
      reason: 'keys used but missing from en_US:\n${missingEn.join('\n')}',
    );
    expect(
      missingMy,
      isEmpty,
      reason: 'keys used but missing from my_MM:\n${missingMy.join('\n')}',
    );
  });
}
