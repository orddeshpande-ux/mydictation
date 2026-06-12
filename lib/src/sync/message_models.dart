import 'dart:convert';

/// Lightweight data model for messages exchanged between devices during
/// Wi‑Fi sync.  All payloads are JSON‑serialisable.
class SyncMessage {
  /// Message type: `recording`, `document`, `preference`, `ping`, `pong`.
  final String type;

  /// Human‑readable filename (only for file transfers).
  final String? filename;

  /// Base64‑encoded file bytes (only for file transfers).
  final String? payload;

  /// Epoch‑millisecond timestamp – used for conflict resolution (newer wins).
  final int timestamp;

  SyncMessage({
    required this.type,
    this.filename,
    this.payload,
    required this.timestamp,
  });

  factory SyncMessage.fromJson(Map<String, dynamic> json) => SyncMessage(
        type: json['type'] as String,
        filename: json['filename'] as String?,
        payload: json['payload'] as String?,
        timestamp: json['timestamp'] as int,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        if (filename != null) 'filename': filename,
        if (payload != null) 'payload': payload,
        'timestamp': timestamp,
      };

  String encode() => jsonEncode(toJson());

  static SyncMessage decode(String raw) =>
      SyncMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Convenience: create a `ping` message for device discovery.
  factory SyncMessage.ping() => SyncMessage(
        type: 'ping',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  /// Convenience: create a `pong` reply.
  factory SyncMessage.pong() => SyncMessage(
        type: 'pong',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
}
