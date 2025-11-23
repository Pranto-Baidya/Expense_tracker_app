
import 'package:expense_tracker_app/storage_service/storage_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:local_auth/local_auth.dart';

final authProvider = StateNotifierProvider<AuthNotifier,AuthState>((ref)=>AuthNotifier());

class AuthState{
  final bool isAuthenticated;
  final String errorMsg;
  final bool isPinSet;

  AuthState({
    this.isAuthenticated = false,
    this.errorMsg = '',
    this.isPinSet = false
  });

  AuthState copyWith({bool? isAuthenticated,String? errorMsg,bool? isPinSet}){
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMsg: errorMsg ?? this.errorMsg,
      isPinSet: isPinSet ?? this.isPinSet
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
      state = state.copyWith(errorMsg: '');

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
        localizedReason: 'Please verify',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      state = state.copyWith(
        isAuthenticated: didAuthenticate,
        errorMsg: didAuthenticate ? '' : 'Authentication failed',
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        errorMsg: e.toString(),
      );
    }
  }


  Future<void> initPass()async{
    final hasPin = await StorageService.hasPass();
    state = state.copyWith(isPinSet: hasPin);
  }

  Future<void> savePass(String pass)async{
    try {
      if (pass.isEmpty) {
        state = state.copyWith(errorMsg: 'Password can not be empty',isPinSet: false);
        return;
      }
      await StorageService.savePassword(pass);
      state = state.copyWith(isPinSet: true);
    }
    catch(e){
      state = state.copyWith(isPinSet: false,errorMsg: e.toString());
    }
  }

  Future<void> verifyPass(String pass)async{

    final savedPass = await StorageService.loadPassword();

    if(savedPass==null){
      state = state.copyWith(isAuthenticated: false,errorMsg: 'Pin is not set yet');
    }
    else if(savedPass!=pass){
      state = state.copyWith(isAuthenticated: false,errorMsg: 'Wrong PIN, Try again');
    }
    else{
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<void> deletePin()async{
    await StorageService.deletePass();
    state = state.copyWith(isAuthenticated: false,isPinSet: false);
  }
}