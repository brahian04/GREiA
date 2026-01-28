import '../../../clients/data/models/client_model.dart';

class Ticket {
  final String id;
  final int humanId;
  final String clientId;
  final Client? client; // Para cuando hagamos join
  final String deviceType;
  final String brand;
  final String model;
  final String? serialNumber;
  final String problemDescription;
  final String status; // 'pendiente', 'revision', etc.
  final String priority;
  final String? technicalSolution;
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.humanId,
    required this.clientId,
    this.client,
    required this.deviceType,
    required this.brand,
    required this.model,
    this.serialNumber,
    required this.problemDescription,
    required this.status,
    required this.priority,
    this.technicalSolution,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      humanId: json['human_id'] ?? 0,
      clientId: json['client_id'],
      client: json['clients'] != null ? Client.fromJson(json['clients']) : null,
      deviceType: json['device_type'],
      brand: json['brand'],
      model: json['model'],
      serialNumber: json['serial_number'],
      problemDescription: json['problem_description'],
      status: json['status'] ?? 'pendiente',
      priority: json['priority'] ?? 'media',
      technicalSolution: json['technical_solution'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'device_type': deviceType,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'problem_description': problemDescription,
      'status': status,
      'priority': priority,
      'technical_solution': technicalSolution,
    };
  }
}
