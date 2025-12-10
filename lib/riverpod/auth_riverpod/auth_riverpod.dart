
import 'package:expense_tracker_app/storage_service/storage_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:local_auth/local_auth.dart';

final authProvider = StateNotifierProvider<AuthNotifier,AuthState>((ref)=>AuthNotifier());

class AuthState{
  final bool isAuthenticated;
  final String errorMsg;
  final bool isPinSet;
  final bool isLoading;
  final bool appLoading;

  AuthState({
    this.isAuthenticated = false,
    this.errorMsg = '',
    this.isPinSet = false,
    this.isLoading = false,
    this.appLoading = true
  });

  AuthState copyWith({bool? isAuthenticated,String? errorMsg,bool? isPinSet,bool? isLoading, bool? appLoading}){
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMsg: errorMsg ?? this.errorMsg,
      isPinSet: isPinSet ?? this.isPinSet,
      isLoading: isLoading ?? this.isLoading,
      appLoading: appLoading ?? this.appLoading
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState>{

  final LocalAuthentication localAuthentication = LocalAuthentication();

  AuthNotifier() : super(AuthState()){
    initPass();
  }

  Future<void> authenticateUser() async {
    try {
      state = state.copyWith(errorMsg: '',isLoading: true);

      final isSupported = await localAuthentication.isDeviceSupported();
      final canCheck = await localAuthentication.canCheckBiometrics;
      final available = await localAuthentication.getAvailableBiometrics();

      if (!isSupported || !canCheck || available.isEmpty) {
        state = state.copyWith(
          isAuthenticated: false,
          errorMsg: 'Biometric not available or not enrolled.',
        );
        return;
      }

      final didAuthenticate = await localAuthentication.authenticate(
        localizedReason: 'Please verify to access',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true
        ),
      );

      state = state.copyWith(
        isAuthenticated: didAuthenticate,
        errorMsg: didAuthenticate ? '' : 'Authentication failed',
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        errorMsg: e.toString(),
        isLoading: false
      );
    }
  }


  Future<void> initPass() async {
    final hasPin = await StorageService.hasPass();
    state = state.copyWith(isPinSet: hasPin, appLoading: false);
  }


  Future<void> savePass(String pass) async {
    try {
      state = state.copyWith(isLoading: true);

      if (pass.isEmpty) {
        state = state.copyWith(
          errorMsg: 'Password cannot be empty',
          isPinSet: false,
          isLoading: false,
        );
        return;
      }

      await StorageService.savePassword(pass);

      state = state.copyWith(
        isPinSet: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isPinSet: false,
        errorMsg: e.toString(),
        isLoading: false,
      );
    }
  }


  Future<void> verifyPass(String pass) async {
    state = state.copyWith(isLoading: true);

    final savedPass = await StorageService.loadPassword();

    if (savedPass == null) {
      state = state.copyWith(
        isAuthenticated: false,
        errorMsg: 'Pin is not set yet',
        isLoading: false,
      );
    } else if (savedPass != pass) {
      state = state.copyWith(
        isAuthenticated: false,
        errorMsg: 'Wrong PIN, Try again',
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
      );
    }
  }


  Future<void> deletePin()async{
    await StorageService.deletePass();
    state = state.copyWith(isAuthenticated: false,isPinSet: false);
  }
}