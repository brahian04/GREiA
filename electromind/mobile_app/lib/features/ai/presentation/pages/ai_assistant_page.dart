import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../tickets/data/models/ticket_model.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../tickets/presentation/cubit/tickets_cubit.dart';
import '../cubit/ai_cubit.dart';
import '../../domain/entities/chat_message.dart';

class AiAssistantPage extends StatefulWidget {
  final String? initialContext;
  final List<ChatMessage>? initialMessages; // New parameter

  const AiAssistantPage({super.key, this.initialContext, this.initialMessages});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      _messages.addAll(widget.initialMessages!);
      // Scroll to bottom after frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      _messages.add(
        ChatMessage(
          text: _getGreetingMessage(),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    if (widget.initialContext != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: 'He detectado el siguiente contexto:\n\n'
                    '**${widget.initialContext}**\n\n'
                    'Puedes preguntarme sobre soluciones comunes, costos estimados o diagramas.',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _scrollToBottom();
          });
        }
      });
    }
  }

  void _handleSend() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _textCtrl.clear();
      _isTyping = true;
      _scrollToBottom();
    });

    // Enviar a la IA real
    context.read<AiCubit>().sendMessage(text, context: widget.initialContext);
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

  void _showRegistrationConfirmation(
      BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.app_registration, color: Colors.deepPurple),
            SizedBox(width: 10),
            Text('Confirmar Registro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${data['client_name']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Tel: ${data['phone']}'),
            const Divider(),
            Text(
                'Equipo: ${data['device_type']} ${data['brand']} ${data['model']}'),
            const SizedBox(height: 5),
            Text('Falla:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(data['problem_description']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Registrar'),
            onPressed: () {
              Navigator.pop(ctx);
              _registerTicket(data);
            },
          ),
        ],
      ),
    );
  }

  void _registerTicket(Map<String, dynamic> data) {
    try {
      final clientId = const Uuid().v4();
      final newClient = Client(
        id: clientId,
        fullName: data['client_name'],
        phone: data['phone'],
        createdAt: DateTime.now(),
      );

      final newTicket = Ticket(
        id: const Uuid().v4(),
        humanId: 0,
        clientId: clientId,
        deviceType: data['device_type'],
        brand: data['brand'],
        model: data['model'],
        problemDescription: data['problem_description'],
        status: 'pendiente',
        priority: 'media',
        createdAt: DateTime.now(),
      );

      context
          .read<TicketsCubit>()
          .createTicket(newTicket, newClient: newClient);

      // La confirmación visual ahora se maneja en el BlocListener de TicketsCubit
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando ticket: $e')),
      );
    }
  }

  String _getGreetingMessage() {
    if (widget.initialContext == null) {
      return 'Hola, soy Electromind AI. 🧠\n¿En qué puedo ayudarte hoy?';
    }

    final ctx = widget.initialContext!.toLowerCase();

    if (ctx.contains('inventario')) {
      return 'Hola. 📦\nPuedo ayudarte a buscar repuestos, verificar stock o registrar entradas.';
    } else if (ctx.contains('clientes')) {
      return 'Gestión de Clientes. 👥\n¿Necesitas buscar a alguien o registrar un nuevo cliente?';
    } else if (ctx.contains('taller') || ctx.contains('dashboard')) {
      return 'Asistente de Taller activo. 🔧\nPregúntame sobre fallas, costos o crea un nuevo ticket.';
    } else {
      return 'Hola, soy Electromind AI. 🧠\n¿En qué puedo ayudarte hoy?';
    }
  }

  @override
  Widget build(BuildContext context) {
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

        // Handle Actions
        if (state is AiLoaded &&
            state.action == 'register_ticket' &&
            state.actionData != null) {
          _showRegistrationConfirmation(context, state.actionData!);
        }
      },
      child: Builder(builder: (context) {
        return BlocListener<TicketsCubit, TicketsState>(
          listener: (context, state) {
            if (state is TicketCreated) {
              setState(() {
                _messages.add(ChatMessage(
                  text: '✅ Ticket registrado exitosamente en el sistema.',
                  isUser: false,
                  timestamp: DateTime.now(),
                ));
              });
              _scrollToBottom();
            } else if (state is TicketsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error guardando ticket: ${state.message}'),
                    backgroundColor: Colors.red),
              );
            }
          },
          child: Builder(builder: (context) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Electromind AI',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text('En línea',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'clear') {
                        setState(() {
                          _messages.clear();
                          _messages.add(
                            ChatMessage(
                              text:
                                  'Chat limpiado. ¿En qué más puedo ayudarte?',
                              isUser: false,
                              timestamp: DateTime.now(),
                            ),
                          );
                        });
                      } else if (value == 'about') {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Electromind AI',
                          applicationVersion: '1.0.0',
                          applicationIcon:
                              const Icon(Icons.psychology, size: 40),
                          children: [
                            const Text(
                                'Asistente inteligente para técnicos de reparación.'),
                          ],
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.cleaning_services, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Limpiar conversación'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'about',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Acerca de'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Banner de Contexto (Sticky)
                  if (widget.initialContext != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color:
                          theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: theme.colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.initialContext!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onTertiaryContainer,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Lista de Mensajes
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return const _TypingIndicator();
                        }
                        final msg = _messages[index];
                        return _ChatBubble(message: msg);
                      },
                    ),
                  ),

                  // Área de Input
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text('Tomar Foto'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Implementar cámara
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.image),
                                        title: const Text('Galería'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Implementar galería
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.attach_file),
                                        title: const Text('Documento'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Implementar documentos
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _textCtrl,
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey.withOpacity(0.2)
                                    : Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _handleSend(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            onPressed: _handleSend,
                            mini: true,
                            elevation: 0,
                            child: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }), // Builder interno
        ); // BlocListener interno (TicketsCubit)
      }), // Builder externo
    ); // BlocListener externo (AiCubit)
  }
}

// End of file class removed
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? theme.primaryColor
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                ),
                tableBody: TextStyle(
                  fontSize: 13,
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                ),
                tableHead: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                ),
                tableBorder: TableBorder.all(
                  color: isUser ? Colors.white24 : Colors.grey.shade400,
                  width: 0.5,
                ),
                code: TextStyle(
                  backgroundColor: Colors.transparent,
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
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
                    color:
                        isUser ? Colors.white12 : Colors.grey.withOpacity(0.2),
                  ),
                ),
                codeblockPadding: const EdgeInsets.all(8),
                blockquotePadding: const EdgeInsets.only(left: 14),
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: isUser ? Colors.white70 : theme.primaryColor,
                      width: 4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isUser
                    ? Colors.white70
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: const SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircleAvatar(radius: 3, backgroundColor: Colors.grey),
              CircleAvatar(radius: 3, backgroundColor: Colors.grey),
              CircleAvatar(radius: 3, backgroundColor: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
