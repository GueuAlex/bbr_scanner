import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Payload décodé d'un QR code
class QrPayload {
  final String ticketId;
  final String type;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? context;
  final String version;

  QrPayload({
    required this.ticketId,
    this.type = 'BBR',
    this.issuedAt,
    this.expiresAt,
    this.context,
    this.version = '1',
  });

  factory QrPayload.fromJson(Map<String, dynamic> json) {
    return QrPayload(
      ticketId: json['tkt'] as String,
      type: json['typ'] as String? ?? 'BBR',
      issuedAt: json['iat'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['iat'] as int) * 1000)
          : null,
      expiresAt: json['exp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['exp'] as int) * 1000)
          : null,
      context: json['ctx'] as String?,
      version: json['v'] as String? ?? '1',
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Service de décodage et validation des QR codes
class QrDecoderService {
  final _logger = Logger();

  /// Décode un QR code (format JWT ou JSON+signature)
  Future<QrPayload?> decode(String rawQrData) async {
    try {
      _logger.d('Decoding QR: ${rawQrData.substring(0, rawQrData.length > 50 ? 50 : rawQrData.length)}...');

      // Tenter décodage JWT d'abord
      final jwtPayload = await _tryDecodeJwt(rawQrData);
      if (jwtPayload != null) {
        _logger.i('QR decoded successfully (JWT)');
        return jwtPayload;
      }

      // Tenter décodage JSON+signature
      final jsonPayload = await _tryDecodeJsonSignature(rawQrData);
      if (jsonPayload != null) {
        _logger.i('QR decoded successfully (JSON)');
        return jsonPayload;
      }

      // Fallback: JSON simple (mode demo sans signature)
      final simplePayload = _tryDecodeSimpleJson(rawQrData);
      if (simplePayload != null) {
        _logger.w('QR decoded (simple JSON, no signature verification)');
        return simplePayload;
      }

      _logger.e('Failed to decode QR with any format');
      return null;
    } catch (e, stack) {
      _logger.e('Error decoding QR: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Tente de décoder un JWT avec vérification signature
  Future<QrPayload?> _tryDecodeJwt(String token) async {
    try {
      final publicKeyPem = dotenv.env['ENV_PUBLIC_KEY_PEM'];

      if (publicKeyPem == null || publicKeyPem.isEmpty || publicKeyPem.contains('...')) {
        // Mode demo: pas de clé publique configurée, on décode sans vérifier
        _logger.w('No public key configured, decoding JWT without verification');
        final jwt = JWT.decode(token);
        return QrPayload.fromJson(jwt.payload as Map<String, dynamic>);
      }

      // Vérification complète avec signature
      final jwt = JWT.verify(
        token,
        RSAPublicKey(publicKeyPem),
        checkExpiresIn: false, // On gère l'expiration nous-mêmes avec tolérance
      );

      return QrPayload.fromJson(jwt.payload as Map<String, dynamic>);
    } catch (e) {
      _logger.d('Not a valid JWT or signature invalid: $e');
      return null;
    }
  }

  /// Tente de décoder JSON avec signature HMAC
  Future<QrPayload?> _tryDecodeJsonSignature(String data) async {
    try {
      final parts = data.split('.');
      if (parts.length != 2) return null;

      final payloadBase64 = parts[0];
      final signatureBase64 = parts[1];

      // Décoder payload
      final payloadJson = utf8.decode(base64Url.decode(payloadBase64));
      final payload = json.decode(payloadJson) as Map<String, dynamic>;

      // TODO: Vérifier signature HMAC si nécessaire
      _logger.d('Decoded JSON payload (signature check skipped for demo)');

      return QrPayload.fromJson(payload);
    } catch (e) {
      _logger.d('Not a valid JSON+signature format: $e');
      return null;
    }
  }

  /// Décode JSON simple sans vérification (mode demo/test)
  QrPayload? _tryDecodeSimpleJson(String data) {
    try {
      final payload = json.decode(data) as Map<String, dynamic>;
      return QrPayload.fromJson(payload);
    } catch (e) {
      _logger.d('Not a valid simple JSON: $e');
      return null;
    }
  }
}
