import 'package:equatable/equatable.dart';

/// Domain entity describing a colleague in the directory.
class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.email,
    required this.phone,
    required this.dateOfJoining,
    this.managerId,
  });

  final String id;
  final String name;
  final String designation;
  final String department;
  final String email;
  final String phone;
  final DateTime dateOfJoining;

  /// Id of the reporting manager; `null` for the top of the org chart.
  final String? managerId;

  @override
  List<Object?> get props =>
      [id, name, designation, department, email, phone, dateOfJoining, managerId];
}