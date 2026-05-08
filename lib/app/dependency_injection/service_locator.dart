import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/network/websocket_service.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';
import 'package:discovaa/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:discovaa/features/authentication/data/datasources/device_token_remote_datasource.dart';
import 'package:discovaa/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:discovaa/features/authentication/domain/repositories/auth_repository.dart';
import 'package:discovaa/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:discovaa/features/payments/data/repositories/refund_repository_impl.dart';
import 'package:discovaa/features/payments/domain/repositories/payment_repository.dart';
import 'package:discovaa/features/payments/domain/repositories/refund_repository.dart';
import 'package:discovaa/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:discovaa/features/profile/domain/repositories/profile_repository.dart';

final GetIt sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Run network-related initializations concurrently
  await Future.wait([_initHive(), _initNetworkInfo()]);
  // DioClient depends on NetworkInfo, so initialize after
  await _initDioClient();
  // Auth depends on both DioClient and HiveService
  await _initAuth();
  // Profile repository with caching support
  await _initProfile();
  // Payment repository for payment operations
  _initPayment();
  // Refund repository for refund operations
  _initRefund();
  // WebSocket service for real-time communication
  _initWebSocketService();
}

Future<void> _initHive() async {
  final hiveService = HiveService.instance;
  await hiveService.init();
  sl.registerSingleton<HiveService>(hiveService);

  // Register FlutterSecureStorage
  const secureStorage = FlutterSecureStorage(aOptions: AndroidOptions());
  sl.registerSingleton<FlutterSecureStorage>(secureStorage);

  // Register SecureTokenStorage which depends on HiveService and FlutterSecureStorage
  sl.registerSingleton<SecureTokenStorage>(
    SecureTokenStorage(hiveService: hiveService, secureStorage: secureStorage),
  );
}

Future<void> _initNetworkInfo() async {
  final connectivity = Connectivity();
  sl.registerSingleton<NetworkInfo>(
    NetworkInfoImpl(connectivity: connectivity),
  );
}

Future<void> _initDioClient() async {
  final dioClient = DioClient(
    networkInfo: sl<NetworkInfo>(),
    tokenStorage: sl<SecureTokenStorage>(),
  );
  sl.registerSingleton<DioClient>(dioClient);
}

// Clean up
Future<void> resetDependencies() async {
  await sl.reset();
}

Future<void> _initAuth() async {
  // Register AuthRemoteDataSource
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      dioClient: sl<DioClient>(),
      tokenStorage: sl<SecureTokenStorage>(),
    ),
  );

  // Register DeviceTokenRemoteDataSource
  sl.registerLazySingleton<DeviceTokenRemoteDataSource>(
    () => DeviceTokenRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  // Register AuthRepository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      deviceTokenDataSource: sl<DeviceTokenRemoteDataSource>(),
    ),
  );
}

Future<void> _initProfile() async {
  // Register ProfileRepository with caching dependencies
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      dioClient: sl<DioClient>(),
      hiveService: sl<HiveService>(),
      networkInfo: sl<NetworkInfo>(),
      tokenStorage: sl<SecureTokenStorage>(),
    ),
  );
}

/// Initialize PaymentRepository
void _initPayment() {
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl<DioClient>()),
  );
}

/// Initialize RefundRepository
void _initRefund() {
  sl.registerLazySingleton<RefundRepository>(
    () => RefundRepositoryImpl(sl<DioClient>()),
  );
}

void _initWebSocketService() {
  // Register WebSocketService as a lazy singleton
  sl.registerLazySingleton<WebSocketService>(
    () => WebSocketService(tokenStorage: sl<SecureTokenStorage>()),
  );
}
