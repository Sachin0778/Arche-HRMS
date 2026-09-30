import 'package:hive_flutter/hive_flutter.dart';

import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/claims/data/datasources/claim_local_data_source.dart';
import '../features/claims/data/datasources/receipt_file_store.dart';
import '../features/claims/data/repositories/claim_repository_impl.dart';
import '../features/claims/domain/repositories/claim_repository.dart';
import '../features/employees/data/datasources/employee_local_data_source.dart';
import '../features/employees/data/repositories/employee_repository_impl.dart';
import '../features/employees/domain/repositories/employee_repository.dart';

/// Composition root. Opens the Hive boxes, seeds them on first launch and
/// wires the data layer into the repository interfaces the UI depends on.
class AppDependencies {
  AppDependencies._({
    required this.authRepository,
    required this.employeeRepository,
    required this.claimRepository,
    required this.receiptFileStore,
  });

  final AuthRepository authRepository;
  final EmployeeRepository employeeRepository;
  final ClaimRepository claimRepository;
  final ReceiptFileStore receiptFileStore;

  static Future<AppDependencies> init() async {
    await Hive.initFlutter();

    final employeeBox = await Hive.openBox<Map>(EmployeeLocalDataSource.boxName);
    final claimBox = await Hive.openBox<Map>(ClaimLocalDataSource.boxName);
    final sessionBox = await Hive.openBox<String>(AuthLocalDataSource.boxName);

    final employeeLocal = EmployeeLocalDataSource(employeeBox);
    final claimLocal = ClaimLocalDataSource(claimBox);
    await employeeLocal.seedIfEmpty();
    await claimLocal.seedIfEmpty();

    final employeeRepository = EmployeeRepositoryImpl(employeeLocal);
    return AppDependencies._(
      employeeRepository: employeeRepository,
      claimRepository: ClaimRepositoryImpl(claimLocal),
      authRepository: AuthRepositoryImpl(AuthLocalDataSource(sessionBox), employeeRepository),
      receiptFileStore: ReceiptFileStore(),
    );
  }
}