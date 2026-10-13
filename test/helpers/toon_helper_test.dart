// test/helpers/toon_helper_test.dart
//
// TOON encoder: compact tabular serialization for the AI context payloads.
import 'package:flutter_test/flutter_test.dart';
import 'package:rexone_mobile/helpers/helpers.dart';

void main() {
  group('Toon.encode', () {
    test('scalars stay bare when unambiguous, quoted when not', () {
      expect(Toon.encode({'a': 'hello world'}), 'a: hello world');
      expect(Toon.encode({'a': 'with, comma'}), 'a: "with, comma"');
      expect(Toon.encode({'a': 'colon: here'}), 'a: "colon: here"');
      expect(Toon.encode({'a': 'line\nbreak'}), 'a: "line\\nbreak"');
      expect(Toon.encode({'a': '42'}), 'a: "42"');
      expect(Toon.encode({'a': ''}), 'a: ""');
      expect(Toon.encode({'a': 'true'}), 'a: "true"');
      expect(Toon.encode({'a': 'say "hi"'}), 'a: "say \\"hi\\""');
      expect(
        Toon.encode({'n': 3, 'b': false, 'z': null}),
        'n: 3\nb: false\nz: null',
      );
    });

    test('uniform object arrays collapse into a table', () {
      final toon = Toon.encode({
        'atoms': [
          {'title': 'Alpha', 'source': 'note', 'content': 'alpha note'},
          {'title': 'Beta', 'source': 'note', 'content': 'b, comma'},
        ],
      });
      expect(
        toon,
        'atoms[2]{title,source,content}:\n'
        '  Alpha,note,alpha note\n'
        '  Beta,note,"b, comma"',
      );
    });

    test('nested objects indent', () {
      final toon = Toon.encode({
        'molecule': {'name': 'M', 'count': 2},
      });
      expect(toon, 'molecule:\n  name: M\n  count: 2');
    });

    test('empty arrays and objects', () {
      expect(Toon.encode({'atoms': []}), 'atoms[0]:');
      expect(Toon.encode({'meta': {}}), 'meta:');
    });

    test('non-uniform items fall back to the expanded form', () {
      final toon = Toon.encode({
        'items': [
          {'a': 1},
          {'b': 2},
        ],
      });
      expect(toon, contains('items[2]:'));
      expect(toon, contains('- a: 1'));
      expect(toon, contains('- b: 2'));
    });

    test('scalar arrays stay inline', () {
      expect(Toon.encode({'tags': ['one', 'two']}), 'tags[2]: one,two');
    });
  });
}
