import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniscribe_ai/src/sync/message_models.dart';

void main() {
  group('SyncMessage', () {
    test('round-trips through JSON', () {
      final msg = SyncMessage(
        type: 'recording',
        filename: 'dictation_01.wav',
        payload: 'AQID', // base64 of [1,2,3]
        timestamp: 1718100000000,
      );

      final json = msg.toJson();
      final restored = SyncMessage.fromJson(json);

      expect(restored.type, 'recording');
      expect(restored.filename, 'dictation_01.wav');
      expect(restored.payload, 'AQID');
      expect(restored.timestamp, 1718100000000);
    });

    test('encode / decode produce identical objects', () {
      final original = SyncMessage(
        type: 'document',
        filename: 'notes.txt',
        payload: 'SGVsbG8=',
        timestamp: 1718200000000,
      );

      final encoded = original.encode();
      final decoded = SyncMessage.decode(encoded);

      expect(decoded.type, original.type);
      expect(decoded.filename, original.filename);
      expect(decoded.payload, original.payload);
      expect(decoded.timestamp, original.timestamp);
    });

    test('ping message has no payload', () {
      final ping = SyncMessage.ping();
      expect(ping.type, 'ping');
      expect(ping.payload, isNull);
      expect(ping.filename, isNull);
      expect(ping.timestamp, isPositive);
    });

    test('pong message has no payload', () {
      final pong = SyncMessage.pong();
      expect(pong.type, 'pong');
      expect(pong.payload, isNull);
      expect(pong.filename, isNull);
      expect(pong.timestamp, isPositive);
    });

    test('toJson omits null fields', () {
      final msg = SyncMessage.ping();
      final json = msg.toJson();

      expect(json.containsKey('payload'), isFalse);
      expect(json.containsKey('filename'), isFalse);
      expect(json.containsKey('type'), isTrue);
      expect(json.containsKey('timestamp'), isTrue);
    });

    test('conflict resolution: newer timestamp wins', () {
      final older = SyncMessage(
        type: 'recording',
        filename: 'file.wav',
        payload: 'old',
        timestamp: 1000,
      );
      final newer = SyncMessage(
        type: 'recording',
        filename: 'file.wav',
        payload: 'new',
        timestamp: 2000,
      );

      // Simulate: keep the one with larger timestamp
      final winner =
          older.timestamp >= newer.timestamp ? older : newer;
      expect(winner.payload, 'new');
      expect(winner.timestamp, 2000);
    });
  });
}
