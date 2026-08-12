import 'package:ferret/src/core/ferret_message_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FerretMessageSize', () {
    test('counts headers and body bytes', () {
      final bytes = FerretMessageSize.bytes(
        headers: const {'content-type': 'application/json'},
        body: '{"ok":true}',
      );
      expect(bytes, greaterThan(0));
    });

    test('reads headers case-insensitively', () {
      expect(
        FerretMessageSize.header(const {
          'Content-Type': 'application/json',
        }, 'content-type'),
        'application/json',
      );
    });
  });
}
