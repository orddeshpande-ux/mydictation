import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'message_models.dart';

/// Automatic Wi‑Fi sync manager.
///
/// Uses a lightweight HTTP server (dart:io) on a fixed port so that devices
/// on the **same home Wi‑Fi** can discover each other automatically.
///
/// Flow:
/// 1. On launch, start an HTTP server on [_port].
/// 2. Periodically broadcast UDP pings on the LAN subnet.
/// 3. When a peer responds (pong), record its IP.
/// 4. Send / receive files via HTTP POST between peers.
///
/// No user configuration is needed – the app handles everything.
class SyncManager extends ChangeNotifier {
  // ── Constants ──────────────────────────────────────────────────
  static const int _httpPort = 51337; // Fixed port for the embedded server
  static const int _udpPort  = 51338; // Fixed port for UDP discovery
  static const Duration _scanInterval = Duration(seconds: 30);
  static const String _serviceId = 'omniscribe-ai-sync';

  // ── State ──────────────────────────────────────────────────────
  HttpServer? _server;
  RawDatagramSocket? _udpSocket;
  Timer? _scanTimer;

  bool _isDiscovering = false;
  bool _isConnected   = false;
  bool _isSyncing     = false;
  String? _peerAddress;
  String _statusText  = '';

  bool   get isDiscovering => _isDiscovering;
  bool   get isConnected   => _isConnected;
  bool   get isSyncing     => _isSyncing;
  String get statusText    => _statusText;
  String? get peerAddress  => _peerAddress;

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Call once from `main()` before `runApp()`.
  Future<void> initialize() async {
    await _startHttpServer();
    await _startUdpDiscovery();
    _scanTimer = Timer.periodic(_scanInterval, (_) => _broadcastPing());
    // Kick off an initial scan immediately.
    _broadcastPing();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _udpSocket?.close();
    _server?.close(force: true);
    super.dispose();
  }

  // ── HTTP server (receives files from peer) ─────────────────────

  Future<void> _startHttpServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _httpPort);
      debugPrint('SyncManager: HTTP server listening on port $_httpPort');
      _server!.listen(_handleHttpRequest);
    } catch (e) {
      debugPrint('SyncManager: Failed to start HTTP server – $e');
    }
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    try {
      if (request.method == 'POST' && request.uri.path == '/sync') {
        final body = await utf8.decoder.bind(request).join();
        final msg = SyncMessage.decode(body);
        await _handleIncomingMessage(msg);
        request.response
          ..statusCode = HttpStatus.ok
          ..write('OK');
        await request.response.close();
      } else if (request.method == 'GET' && request.uri.path == '/ping') {
        // Simple health‑check used after UDP discovery.
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'service': _serviceId}));
        await request.response.close();
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (e) {
      debugPrint('SyncManager: HTTP error – $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  Future<void> _handleIncomingMessage(SyncMessage msg) async {
    switch (msg.type) {
      case 'recording':
      case 'document':
        if (msg.filename != null && msg.payload != null) {
          final dir = await getApplicationDocumentsDirectory();
          final syncDir = Directory('${dir.path}/OmniScribe/sync');
          if (!syncDir.existsSync()) syncDir.createSync(recursive: true);

          final file = File('${syncDir.path}/${msg.filename}');
          // Conflict resolution: newer timestamp wins
          if (file.existsSync()) {
            final existing = file.lastModifiedSync();
            if (existing.millisecondsSinceEpoch >= msg.timestamp) {
              debugPrint('SyncManager: Skipping ${msg.filename} (local is newer)');
              return;
            }
          }
          await file.writeAsBytes(base64Decode(msg.payload!));
          debugPrint('SyncManager: Received ${msg.filename}');
        }
        break;
      default:
        debugPrint('SyncManager: Unknown message type ${msg.type}');
    }
  }

  // ── UDP discovery ──────────────────────────────────────────────

  Future<void> _startUdpDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _udpPort,
        reuseAddress: true,
        reusePort: Platform.isAndroid || Platform.isLinux, // not all OSes support this
      );
      _udpSocket!.broadcastEnabled = true;
      _udpSocket!.listen(_handleUdpEvent);
      debugPrint('SyncManager: UDP discovery socket on port $_udpPort');
    } catch (e) {
      debugPrint('SyncManager: UDP bind failed – $e');
    }
  }

  void _handleUdpEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _udpSocket?.receive();
    if (datagram == null) return;

    final data = utf8.decode(datagram.data);
    if (data.startsWith('$_serviceId:pong')) {
      final peerIp = datagram.address.address;
      if (_peerAddress != peerIp) {
        _peerAddress = peerIp;
        _isConnected = true;
        _isDiscovering = false;
        _statusText = 'Connected to $peerIp';
        notifyListeners();
        debugPrint('SyncManager: Discovered peer at $peerIp');
      }
    } else if (data.startsWith('$_serviceId:ping')) {
      // Reply with pong so the other device discovers us.
      final replyBytes = utf8.encode('$_serviceId:pong');
      _udpSocket?.send(replyBytes, datagram.address, _udpPort);
    }
  }

  void _broadcastPing() {
    if (_udpSocket == null) return;
    _isDiscovering = true;
    notifyListeners();

    final pingBytes = utf8.encode('$_serviceId:ping');
    // Send to subnet broadcast address (255.255.255.255).
    _udpSocket!.send(
      pingBytes,
      InternetAddress('255.255.255.255'),
      _udpPort,
    );
  }

  // ── Sending files ──────────────────────────────────────────────

  /// Send a file to the connected peer.
  Future<bool> sendFile(File file, {String type = 'recording'}) async {
    if (_peerAddress == null) {
      debugPrint('SyncManager: No peer connected – cannot send');
      return false;
    }

    try {
      _isSyncing = true;
      _statusText = 'Syncing ${file.path.split(Platform.pathSeparator).last}…';
      notifyListeners();

      final bytes = await file.readAsBytes();
      final msg = SyncMessage(
        type: type,
        filename: file.path.split(Platform.pathSeparator).last,
        payload: base64Encode(bytes),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final client = HttpClient();
      final uri = Uri.parse('http://$_peerAddress:$_httpPort/sync');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(msg.encode());
      final response = await request.close();
      await response.drain();
      client.close();

      _isSyncing = false;
      _statusText = 'Synced';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SyncManager: Send failed – $e');
      _isSyncing = false;
      _statusText = 'Sync failed';
      notifyListeners();
      return false;
    }
  }
}
