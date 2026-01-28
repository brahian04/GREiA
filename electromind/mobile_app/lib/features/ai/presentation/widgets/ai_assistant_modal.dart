import 'package:flutter/material.dart';
import 'package:electromind_app/features/tickets/data/models/ticket_model.dart';
import 'package:go_router/go_router.dart';

class AiAssistantModal extends StatefulWidget {
  final String initialContext;
  final Ticket? ticketContext;

  const AiAssistantModal({
    super.key,
    required this.initialContext,
    this.ticketContext,
  });

  @override
  State<AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<AiAssistantModal> {
  final TextEditingController _promptCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Electromind AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.open_in_full),
                  tooltip: 'Expandir a pantalla completa',
                  onPressed: () {
                    Navigator.pop(context); // Cerrar Modal
                    context.push('/ai-chat', extra: _getContextSummary());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

          // Context Info (Hidden text or visible hint)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.primaryColor.withOpacity(0.05),
            child: Text(
              _getContextSummary(),
              style: TextStyle(color: theme.primaryColor, fontSize: 12),
            ),
          ),

          // Chat Area (Initial / Placeholder)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              '¿En qué puedo ayudarte con esta reparación?',
              style: TextStyle(color: Colors.grey),
            ),
          ),

          // Input Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu consulta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      fillColor: theme.cardColor,
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: () {
                    // Acción de enviar (Próximamente Integración API)
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getContextSummary() {
    if (widget.ticketContext != null) {
      final t = widget.ticketContext!;
      return 'Contexto: Ticket #${t.humanId} - ${t.deviceType} ${t.model} (${t.problemDescription})';
    }
    return 'Contexto: ${widget.initialContext}';
  }
}
