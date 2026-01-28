import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/tickets_cubit.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.contains('GREIA-TICKET')) {
        // Formato esperado:
        // GREIA-TICKET
        // Ticket ID: #10023
        // Cliente: ...
        // UUID: <uuid>

        final uuidMatch = RegExp(r'UUID: ([a-f0-9\-]+)').firstMatch(rawValue);
        if (uuidMatch != null) {
          final uuid = uuidMatch.group(1);
          if (uuid != null) {
            setState(() => _isScanned = true);
            _navigateToTicket(uuid);
            break;
          }
        }
      }
    }
  }

  void _navigateToTicket(String ticketId) {
    // Buscar el ticket en el Cubit para pasarlo como objeto,
    // pero como GoRouter 'extra' requiere el objeto Ticket y aquí solo tenemos ID,
    // lo ideal sería consultar el repositorio.
    // SIMPLIFICACIÓN: Por ahora, vamos a Dashboard y filtramos o
    // (mejor) hacemos que TicketDetail pueda cargar por ID si no recibe 'extra'.

    // Como TicketDetailPage requiere 'ticket' (objeto) obligatorio en constructor,
    // necesitamos obtenerlo primero.

    context.read<TicketsCubit>().getTicketById(ticketId).then((ticket) {
      if (ticket != null) {
        context.pushReplacement('/tickets/detail', extra: ticket);
      } else {
        setState(
            () => _isScanned = false); // Permitir escanear de nuevo si falla
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket no encontrado')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Ticket')),
      body: MobileScanner(
        onDetect: _onDetect,
        overlayBuilder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(50),
          );
        },
      ),
    );
  }
}
