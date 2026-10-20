import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import 'models/category_model.dart';
import 'models/dashboard_summary_model.dart';
import 'models/user_model.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/transaction_service.dart';

// Core Service Providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthService(client);
});

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final client = ref.watch(apiClientProvider);
  return CategoryService(client);
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final client = ref.watch(apiClientProvider);
  return TransactionService(client);
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AnalyticsService(client);
});

// App State: Currency Provider
class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('INR') {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.currencyKey);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  Future<void> setCurrency(String currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.currencyKey, currency);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

// Auth State
class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;
  final bool isInitialized;

  AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = AuthState(user: user, isInitialized: true);
        _ref.read(currencyProvider.notifier).setCurrency(user.currency);
      } else {
        state = AuthState(isInitialized: true);
      }
    } catch (_) {
      state = AuthState(isInitialized: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.login(email: email, password: password);
      state = AuthState(user: user, isInitialized: true);
      _ref.read(currencyProvider.notifier).setCurrency(user.currency);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, {String currency = 'INR'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        currency: currency,
      );
      state = AuthState(user: user, isInitialized: true);
      _ref.read(currencyProvider.notifier).setCurrency(user.currency);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? currency}) async {
    try {
      final updated = await _authService.updateProfile(name: name, currency: currency);
      state = state.copyWith(user: updated);
      if (currency != null) {
        _ref.read(currencyProvider.notifier).setCurrency(currency);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState(isInitialized: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

// Categories State
final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.watch(categoryServiceProvider);
  return service.getCategories();
});

// Dashboard Summary Provider
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummaryModel>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getDashboardSummary();
});
