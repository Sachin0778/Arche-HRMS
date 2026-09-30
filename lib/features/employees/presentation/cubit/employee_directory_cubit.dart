import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';

part 'employee_directory_state.dart';

class EmployeeDirectoryCubit extends Cubit<EmployeeDirectoryState> {
  EmployeeDirectoryCubit(this._repository) : super(const EmployeeDirectoryState());

  final EmployeeRepository _repository;
  StreamSubscription<List<Employee>>? _subscription;

  void load() {
    emit(state.copyWith(status: DirectoryStatus.loading));
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (employees) {
        final departments = employees.map((e) => e.department).toSet().toList()..sort();
        emit(state.copyWith(
          status: DirectoryStatus.ready,
          employees: employees,
          departments: departments,
        ));
      },
      onError: (Object error) => emit(state.copyWith(
        status: DirectoryStatus.failure,
        errorMessage: 'Could not load the directory: $error',
      )),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  void selectDepartment(String? department) => emit(
        department == null
            ? state.copyWith(clearDepartment: true)
            : state.copyWith(department: department),
      );

  void clearFilters() => emit(state.copyWith(query: '', clearDepartment: true));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}