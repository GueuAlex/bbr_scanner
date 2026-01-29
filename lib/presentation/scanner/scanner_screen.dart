import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_providers.dart';
import '../scanner/scan_result_screen.dart';
import '../../core/constants/enums.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/scan_event.dart';
import 'dart:async';

/// Écran de scanner QR
class ScannerScreen extends ConsumerStatefulWidget {
  final ScanType scanType;

  const ScannerScreen({
    super.key,
    required this.scanType,
  });

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  DateTime? _lastScanTime;
  final _debounceDelay = const Duration(seconds: 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.isEmpty) return;

    // Debounce pour éviter les scans multiples
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < _debounceDelay) {
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _lastScanTime = now;
    });

    // Vibration feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    await _processScan(rawValue);

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processScan(String qrData) async {
    try {
      // 1. Décoder le QR code
      final qrDecoder = ref.read(qrDecoderServiceProvider);
      final payload = await qrDecoder.decode(qrData);

      if (payload == null) {
        _showError('QR code invalide ou corrompu');
        return;
      }

      // 2. Vérifier l'expiration du QR
      if (payload.isExpired) {
        _showError('QR code expiré');
        return;
      }

      // 3. Récupérer ou créer le ticket
      final ticketRepo = ref.read(ticketRepositoryProvider);
      var ticket = await ticketRepo.getTicketById(payload.ticketId);

      if (ticket == null) {
        // Créer un nouveau ticket à partir du payload
        ticket = Ticket(
          id: payload.ticketId,
          code: payload.ticketId,
          status: TicketStatus.newTicket,
          expiresAt: payload.expiresAt,
        );
        await ticketRepo.saveTicket(ticket);
      }

      // 4. Valider le scan selon les règles métier
      final validator = ref.read(validationServiceProvider);
      final config = ref.read(appConfigProvider);
      final validationResult = validator.validateScan(
        ticket: ticket,
        scanType: widget.scanType,
        config: config,
      );

      // 5. Créer l'événement de scan
      final user = ref.read(currentUserProvider);
      final scanEvent = ScanEvent(
        id: const Uuid().v4(),
        ticketId: ticket.id,
        scanType: widget.scanType,
        timestamp: DateTime.now(),
        deviceId: 'device-${user?.id ?? "unknown"}', // TODO: Get real device ID
        agentId: user?.id ?? 'unknown',
        offline: true, // Sera synchronisé plus tard
        verdict: validationResult.verdict,
        reason: validationResult.reason,
      );

      // 6. Sauvegarder l'événement
      final scanRepo = ref.read(scanRepositoryProvider);
      await scanRepo.saveScanEvent(scanEvent);

      // 7. Mettre à jour le statut du ticket si validé
      if (validationResult.isValid && validationResult.newStatus != null) {
        await ticketRepo.updateTicketStatus(ticket.id, validationResult.newStatus!);
        ticket = ticket.copyWith(status: validationResult.newStatus);
      }

      // 8. Naviguer vers l'écran de résultat
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(
              ticket: ticket!,
              scanEvent: scanEvent,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Erreur de traitement: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    // Vibration d'erreur
    Vibration.vibrate(pattern: [0, 100, 100, 100]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scanType.label),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, torchState, child) {
                switch (torchState) {
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                  case TorchState.off:
                  default:
                    return const Icon(Icons.flash_off);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          // Overlay avec viewfinder
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Placez le QR code dans le cadre',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.scanType == ScanType.board
                        ? 'Contrôle Embarquement'
                        : 'Contrôle Débarquement',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Indicateur de traitement
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Traitement...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implémenter la saisie manuelle
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saisie manuelle (À venir)')),
          );
        },
        icon: const Icon(Icons.keyboard),
        label: const Text('Saisie manuelle'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Painter pour l'overlay du scanner
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Dessiner l'overlay avec un trou pour le scanner
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(20),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Dessiner les coins du viewfinder
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;

    // Coin supérieur gauche
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), borderPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), borderPaint);

    // Coin supérieur droit
    canvas.drawLine(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize - cornerLength, top), borderPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize, top + cornerLength), borderPaint);

    // Coin inférieur gauche
    canvas.drawLine(Offset(left, top + scanAreaSize),
        Offset(left + cornerLength, top + scanAreaSize), borderPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize),
        Offset(left, top + scanAreaSize - cornerLength), borderPaint);

    // Coin inférieur droit
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize),
        Offset(left + scanAreaSize - cornerLength, top + scanAreaSize), borderPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize),
        Offset(left + scanAreaSize, top + scanAreaSize - cornerLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
