class TicketHistory {
  final String id;
  final String ticketId;
  final String? note;
  final String? actionType;
  final DateTime createdAt;
  final String? userId;

  TicketHistory({
    required this.id,
    required this.ticketId,
    this.note,
    this.actionType,
    required this.createdAt,
    this.userId,
  });

  factory TicketHistory.fromJson(Map<String, dynamic> json) {
    return TicketHistory(
      id: json['id'],
      ticketId: json['ticket_id'],
      note: json['note'],
      actionType: json['action_type'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
    );
  }
}
