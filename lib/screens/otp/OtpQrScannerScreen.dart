import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:thisjowi/data/repository/otp_repository.dart';
import 'package:thisjowi/components/error_snack_bar.dart';

class OtpQrScannerScreen extends StatefulWidget {
  const OtpQrScannerScreen({super.key});

  @override
  State<OtpQrScannerScreen> createState() => _OtpQrScannerScreenState();
}

class _OtpQrScannerScreenState extends State<OtpQrScannerScreen> {
  late final OtpRepository _otpRepository;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool scanned = false;

  @override
  void initState() {
    super.initState();
    // Initialize repository (local-first)
    _otpRepository = OtpRepository();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller?.scannedDataStream.listen((scanData) async {
      if (scanned) return;
      scanned = true;
      final code = scanData.code ?? '';
      if (code.startsWith('otpauth://')) {
        final result = await _otpRepository.addOtpFromUri(code, '');
        if (result['success'] == true) {
          ErrorSnackBar.showSuccess(context, 'OTP added');
          Navigator.pop(context, true);
        } else {
          ErrorSnackBar.show(context, result['message'] ?? 'Error');
          Navigator.pop(context, false);
        }
      } else {
        ErrorSnackBar.show(context, 'Invalid QR');
        Navigator.pop(context, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan OTP QR')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }
}
