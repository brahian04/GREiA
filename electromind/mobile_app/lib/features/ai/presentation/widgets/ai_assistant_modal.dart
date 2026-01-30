import 'package:flutter/material.dart';
import 'package:electromind_app/features/tickets/data/models/ticket_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ai_cubit.dart';
import '../../domain/entities/chat_message.dart';

import 'package:electromind_app/features/tickets/data/models/ticket_history_model.dart';

class AiAssistantModal extends StatefulWidget {
  final String initialContext;
  final Ticket? ticketContext;
  final List<TicketHistory>? ticketHistory;

  const AiAssistantModal({
    super.key,
    required this.initialContext,
    this.ticketContext,
    this.ticketHistory,
  });

  @override
  State<AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<AiAssistantModal> {
  final TextEditingController _promptCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Mensaje inicial
    _messages.add(
      ChatMessage(
        text: _getGreetingMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _handleSend() {
    final text = _promptCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _promptCtrl.clear();
      _isTyping = true;
      _scrollToBottom();
    });

    // Enviar al Cubit (usando el contexto inicial como referencia)
    context.read<AiCubit>().sendMessage(text, context: _getContextSummary());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Escuchar cambios del AiCubit para actualizar la UI del modal
    return BlocListener<AiCubit, AiState>(
      listener: (context, state) {
        if (state is AiLoaded) {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(
              text: state.response,
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _scrollToBottom();
          });
        } else if (state is AiError) {
          setState(() => _isTyping = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.85, // Max 85% height
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
                      context.push('/ai-chat', extra: {
                        'context': _getContextSummary(),
                        'messages': _messages,
                      });
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Chat Area (Initial / Placeholder)
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(width: 8),
                          Text('Pensando...',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  final msg = _messages[index];
                  // Reusing ChatBubble logic inline or simplified
                  final isUser = msg.isUser;
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isUser
                            ? theme.primaryColor
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MarkdownBody(
                        data: msg.text,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: isUser
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          strong: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUser
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                          tableBody: TextStyle(
                            fontSize: 12,
                            color: isUser
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                          tableHead: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isUser
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                          tableBorder: TableBorder.all(
                            color:
                                isUser ? Colors.white24 : Colors.grey.shade400,
                            width: 0.5,
                          ),
                          code: TextStyle(
                            backgroundColor: Colors.transparent,
                            color: isUser
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: isUser
                                ? Colors.black12
                                : theme.brightness == Brightness.dark
                                    ? Colors.black26
                                    : Colors.white54,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isUser
                                  ? Colors.white12
                                  : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          codeblockPadding: const EdgeInsets.all(8),
                          blockquotePadding: const EdgeInsets.only(left: 14),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: isUser
                                    ? Colors.white70
                                    : theme.primaryColor,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'ai_modal_send_btn',
                    onPressed: _handleSend,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    final ctx = widget.initialContext.toLowerCase();

    if (widget.ticketContext != null) {
      return '¿En qué puedo ayudarte con este ticket?';
    }

    if (ctx.contains('inventario')) {
      return '¿Necesitas ayuda con el stock o repuestos? 📦';
    } else if (ctx.contains('clientes')) {
      return '¿Buscas información de algún cliente? 👥';
    } else if (ctx.contains('taller') || ctx.contains('dashboard')) {
      return '¿Alguna duda técnica o sobre un servicio? 🔧';
    } else {
      return 'Hola, soy tu asistente. ¿En qué te ayudo? 🧠';
    }
  }

  String _getContextSummary() {
    if (widget.ticketContext != null) {
      final t = widget.ticketContext!;
      final dateStr =
          "${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year} ${t.createdAt.hour}:${t.createdAt.minute.toString().padLeft(2, '0')}";
      return 'Ticket Context:\n'
          '- Ticket: #${t.humanId}\n'
          '- Equipo: ${t.deviceType} ${t.brand} ${t.model}\n'
          '- Falla: ${t.problemDescription}\n'
          '- Estado: ${t.status}\n'
          '- Prioridad: ${t.priority}\n'
          '- Fecha Registro: $dateStr\n'
          '- Cliente ID: ${t.clientId}\n'
          '${t.serialNumber != null ? "- Serial: ${t.serialNumber}\n" : ""}'
          '\n--- Historial de Notas ---\n'
          '${_formatHistory()}';
    }
    return '${widget.initialContext}';
  }

  String _formatHistory() {
    if (widget.ticketHistory == null || widget.ticketHistory!.isEmpty) {
      return "No hay notas registradas.";
    }
    return widget.ticketHistory!.map((h) {
      final date =
          "${h.createdAt.day}/${h.createdAt.month} ${h.createdAt.hour}:${h.createdAt.minute.toString().padLeft(2, '0')}";
      return "[$date] ${h.note ?? 'Evento'}";
    }).join('\n');
  }
}

// Shared ChatMessage model used from entities
