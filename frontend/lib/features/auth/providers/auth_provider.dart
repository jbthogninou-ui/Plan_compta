import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/jwt_decoder.dart';
import '../../../core/providers.dart';
import '../../../models/user.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.companyId, this.email, this.error});

  final AuthStatus status;
  final String? companyId;
  final String? email;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, String? companyId, String? email, String? error}) => AuthState(
        status: status ?? this.status,
        companyId: companyId ?? this.companyId,
        email: email ?? this.email,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _bootstrap();
  }

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> _bootstrap() async {
    final hasSession = await _repo.hasSession;
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    final token = await _ref.read(tokenStorageProvider).accessToken;
    final companyId = _extractCompanyId(token);
    state = state.copyWith(status: AuthStatus.authenticated, companyId: companyId);
  }

  /// Extrait le `company_id` du payload JWT.
  /// Fonction séparée pour éviter l'ambiguïté de parsing Dart entre un cast
  /// nullable (`as String?`) et l'opérateur ternaire (`? ... : ...`).
  String? _extractCompanyId(String? token) {
    if (token == null) return null;
    final value = JwtDecoder.payload(token)?['company_id'];
    return value as String?;
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(error: null);
    try {
      await _repo.login(email: email, password: password);
      final token = await _ref.read(tokenStorageProvider).accessToken;
      final companyId = _extractCompanyId(token);
      state = state.copyWith(status: AuthStatus.authenticated, companyId: companyId, email: email);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.message);
      return false;
    }
  }

  Future<bool> register({
    required String companyName,
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(error: null);
    try {
      await _repo.register(companyName: companyName, email: email, password: password, fullName: fullName);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceExpire() {
    state = state.copyWith(status: AuthStatus.unauthenticated, error: 'Votre session a expiré, reconnectez-vous.');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

/// Rôle de l'utilisateur courant — non fourni par le backend aujourd'hui
/// (pas d'endpoint `GET /auth/me`). Voir TODO_BACKEND.md : en attendant,
/// on adopte la posture la plus permissive pour l'UI, la sécurité réelle
/// restant appliquée par le backend sur chaque requête.
final currentUserRoleProvider = Provider<UserRole>((ref) => UserRole.accountant);
