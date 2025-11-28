import 'package:expense_tracker_app/riverpod/auth_riverpod/auth_riverpod.dart';
import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/screens/all_screens.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final wrongProvider = StateProvider<bool>((ref)=>false);

final successProvider = StateProvider<bool>((ref)=>false);

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {

  final TextEditingController _pinController = TextEditingController();

  late FocusNode _pinFocus;

  late AnimationController _animationController;

  late Animation<double> _shakeAnimation;

  late AnimationController _successController;

  late Animation<Offset> _slideAnimation;

  late Animation<double> _fadeAnimation;

  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pinFocus = FocusNode();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticIn,
      ),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 1.5), end: Offset.zero)
        .animate(
        CurvedAnimation(parent: _successController, curve: Curves.easeOutBack)
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(
        CurvedAnimation(parent: _successController, curve: Curves.easeOut)
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOutBack),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinFocus.dispose();
    _pinController.dispose();
    _successController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handlePinContainerTap() {
    _pinFocus.unfocus();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _pinFocus.requestFocus();
      }
    });
  }

  Future<void> _verifyPin(String pin) async {

    await ref.read(authProvider.notifier).verifyPass(pin);

    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {

      _successController.reset();
      _successController.forward();
      ref.read(successProvider.notifier).state = true;
      ref.read(wrongProvider.notifier).state = false;

      Future.delayed(const Duration(milliseconds: 100), () {
        _pinFocus.unfocus();
      });
    } else {
      _animationController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 200), () {
        _pinController.clear();
        ref.read(successProvider.notifier).state = false;
        ref.read(wrongProvider.notifier).state = true;
        _pinFocus.requestFocus();
      });

      if (authState.errorMsg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.errorMsg,style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final _showSuccess = ref.watch(successProvider);

    final isWrong = ref.watch(wrongProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppbar(title: '', toolbarHeight: 0),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 30.h),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.fingerprint, color: theme.iconTheme.color, size: 30),
                    TextButton(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).authenticateUser();

                          final authState = ref.read(authProvider);

                          if (authState.isAuthenticated) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => AllScreens())
                            );
                          } else if (authState.errorMsg.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(authState.errorMsg))
                            );
                          }
                        },
                        child: Text('Use fingerprint instead?', style: theme.textTheme.titleMedium)
                    ),
                  ],
                ),
              ),
              SizedBox(height: 150.h),
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 100),
                    SizedBox(height: 10.h),
                    Text('Enter your PIN', style: theme.textTheme.headlineSmall),
                    SizedBox(height: 10.h),
                    Text('Please enter correct PIN to access', style: theme.textTheme.titleMedium),
                    SizedBox(height: 20.h),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(4, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: GestureDetector(
                                onTap: _handlePinContainerTap,
                                child: Container(
                                  width: 50,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isWrong
                                          ? Border.all(color: Colors.red, width: 2)
                                          : Border.all(color: theme.colorScheme.primary)
                                  ),
                                  child: Text(
                                      _pinController.text.length > index ? '•' : '',
                                      style: theme.textTheme.headlineLarge
                                  ),
                                ),
                              ),
                            );
                          })
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: 0,
                        height: 0,
                        child: TextField(
                          controller: _pinController,
                          autofocus: true,
                          focusNode: _pinFocus,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          onChanged: (value) async {
                            setState(() {});

                            if (value.length < 4) {
                              if (!_pinFocus.hasFocus) {
                                FocusScope.of(context).requestFocus(_pinFocus);
                              }
                            }
                            if (value.length == 4) {
                              await _verifyPin(value);
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    TextButton(
                        onPressed: () async{
                          await ref.read(authProvider.notifier).authenticateUser();

                          final authState = ref.read(authProvider);

                          if (authState.isAuthenticated) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => AllScreens())
                            );
                          } else if (authState.errorMsg.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(authState.errorMsg))
                            );
                          }
                        },
                        child: Text(
                          'Forgot pin code?',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary
                          ),
                        )
                    ),
                    if (_showSuccess) ...[
                      SizedBox(height: 70),
                      Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => AllScreens())
                                      );
                                    },
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                          Icons.arrow_forward,
                                          color: theme.colorScheme.primary,
                                          size: 35
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}