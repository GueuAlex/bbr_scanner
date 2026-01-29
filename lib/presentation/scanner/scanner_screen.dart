import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Écran de scanner QR moderne et épuré
class ScannerScreen extends ConsumerStatefulWidget {
  final ScanType scanType;

  const ScannerScreen({super.key, required this.scanType});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  DateTime? _lastScanTime;
  final _debounceDelay = const Duration(seconds: 1);
  bool _isTorchOn = false;

  // Animations
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  bool _showScanEffect = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Animation de la ligne de scan
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scanAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.isEmpty) return;

    // Debounce
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < _debounceDelay) {
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _lastScanTime = now;
      _showScanEffect = true;
    });

    // Vibration feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    // Animation effect
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showScanEffect = false;
        });
      }
    });

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
        _showError('QR code invalide');
        return;
      }

      // 2. Vérifier l'expiration
      if (payload.isExpired) {
        _showError('QR code expiré');
        return;
      }

      // 3. Récupérer ou créer le ticket
      final ticketRepo = ref.read(ticketRepositoryProvider);
      var ticket = await ticketRepo.getTicketById(payload.ticketId);

      if (ticket == null) {
        ticket = Ticket(
          id: payload.ticketId,
          code: payload.ticketId,
          status: TicketStatus.newTicket,
          expiresAt: payload.expiresAt,
        );
        await ticketRepo.saveTicket(ticket);
      }

      // 4. Valider le scan
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
        deviceId: 'device-${user?.id ?? "unknown"}',
        agentId: user?.id ?? 'unknown',
        offline: true,
        verdict: validationResult.verdict,
        reason: validationResult.reason,
      );

      // 6. Sauvegarder
      final scanRepo = ref.read(scanRepositoryProvider);
      await scanRepo.saveScanEvent(scanEvent);

      // 7. Mettre à jour le statut
      if (validationResult.isValid && validationResult.newStatus != null) {
        await ticketRepo.updateTicketStatus(
          ticket.id,
          validationResult.newStatus!,
        );
        ticket = ticket.copyWith(status: validationResult.newStatus);
      }

      // 8. Naviguer vers résultat
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ScanResultScreen(ticket: ticket!, scanEvent: scanEvent),
          ),
        );
      }
    } catch (e) {
      _showError('Erreur: ${e.toString().substring(0, 30)}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
    Vibration.vibrate(pattern: [0, 100, 100, 100]);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner plein écran
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          // Gradient overlay haut
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton retour
                  _buildIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),

                  // Type de scan
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.scanType.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Bouton flash
                  _buildIconButton(
                    icon: _isTorchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onTap: () {
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                      _controller.toggleTorch();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Zone de scan avec animations
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: Stack(
                children: [
                  // Coins animés
                  ..._buildCorners(scanAreaSize),

                  // Ligne de scan animée
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: scanAreaSize * _scanAnimation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.blue.shade400,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Effet de scan
                  if (_showScanEffect)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Overlay de traitement
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Analyse en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  List<Widget> _buildCorners(double size) {
    const cornerLength = 40.0;
    const cornerWidth = 4.0;
    const color = Colors.white;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerLength,
          height: cornerWidth,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerLength,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
            ),
          ),
        ),
      ),

      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerLength,
          height: cornerWidth,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerLength,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
            ),
          ),
        ),
      ),

      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerLength,
          height: cornerWidth,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerLength,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
            ),
          ),
        ),
      ),

      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerLength,
          height: cornerWidth,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerLength,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
    ];
  }
}
