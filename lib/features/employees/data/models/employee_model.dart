import '../../domain/entities/employee.dart';

/// Serialises [Employee] to/from the plain map stored in Hive.
/// Kept separate from the entity so storage details never leak into domain.
class EmployeeModel {
  EmployeeModel._();

  static Map<String, dynamic> toMap(Employee e) => {
        'id': e.id,
        'name': e.name,
        'designation': e.designation,
        'department': e.department,
        'email': e.email,
        'phone': e.phone,
        'dateOfJoining': e.dateOfJoining.toIso8601String(),
        'managerId': e.managerId,
      };

  static Employee fromMap(Map<dynamic, dynamic> map) => Employee(
        id: map['id'] as String,
        name: map['name'] as String,
        designation: map['designation'] as String,
        department: map['department'] as String,
        email: map['email'] as String,
        phone: map['phone'] as String,
        dateOfJoining: DateTime.parse(map['dateOfJoining'] as String),
        managerId: map['managerId'] as String?,
      );
}