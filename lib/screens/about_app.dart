import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/widgets/listAnimation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> with SingleTickerProviderStateMixin{

  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1200)
    );

    _scaleAnim = Tween<double>(begin: 0.3,end: 1).animate(
        CurvedAnimation(
            parent: _animController,
            curve: Interval(0.0, 0.7, curve: Curves.elasticOut)
        )
    );

    _rotateAnim = Tween<double>(begin: -0.5,end: 0).animate(
        CurvedAnimation(
            parent: _animController,
            curve: Interval(0.0, 0.7, curve: Curves.easeOutBack)
        )
    );

    _fadeAnim = Tween<double>(begin: 0,end: 1).animate(
        CurvedAnimation(
            parent: _animController,
            curve: Interval(0.0, 0.6, curve: Curves.easeIn)
        )
    );

    _slideAnim = Tween<Offset>(begin: Offset(0, -0.5),end: Offset.zero).animate(
        CurvedAnimation(
            parent: _animController,
            curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic)
        )
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage('assets/transparent.png'), context).then((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    bool isDark = ref.watch(themeModeProvider)==ThemeMode.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('About app',style: theme.textTheme.titleLarge,),
        iconTheme: theme.iconTheme,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.25),width: 1))
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarColor: theme.navigationBarTheme.backgroundColor,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark? Brightness.light:Brightness.dark
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: RotationTransition(
                        turns: _rotateAnim,
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset('assets/transparent.png')
                              )
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: const Text(
                        'MoneyMate',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: const Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ListAnimationWidget(
              index: 1,
              offset: Offset(0, 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About MoneyMate',
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'MoneyMate is your personal finance companion, designed to help you track expenses, manage budgets, and achieve your financial goals. Take control of your money with intuitive tools and insightful analytics.',
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 16,color: Colors.grey[600],),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            ListAnimationWidget(
              index: 2,
              offset: Offset(0, 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Key Features',
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          theme,
                          Icons.bar_chart_rounded,
                          'Expense Tracking',
                          'Monitor your spending habits',
                        ),
                        _buildFeatureItem(
                          theme,
                          Icons.savings_rounded,
                          'Budget Management',
                          'Set and track your budgets',
                        ),
                        _buildFeatureItem(
                          theme,
                          Icons.insights_rounded,
                          'Financial Insights',
                          'Get detailed analytics',
                        ),
                        _buildFeatureItem(
                          theme,
                          Icons.security_rounded,
                          'Secure & Private',
                          'Your data is protected',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),


            ListAnimationWidget(
              index: 3,
              offset: Offset(0, 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildLinkTile(
                        theme: theme,
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {

                        },
                      ),
                      Divider(height: 1,color: theme.dividerColor.withOpacity(0.5),),
                      _buildLinkTile(
                        theme: theme,
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () {

                        },
                      ),
                      Divider(height: 1,color: theme.dividerColor.withOpacity(0.5),),
                      _buildLinkTile(
                        theme: theme,
                        icon: Icons.support_agent_outlined,
                        title: 'Contact Support',
                        onTap: () {

                        },
                      ),
                      Divider(height: 1,color: theme.dividerColor.withOpacity(0.5),),
                      _buildLinkTile(
                        theme: theme,
                        icon: Icons.star_border_rounded,
                        title: 'Rate Us',
                        onTap: () {

                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '© 2026 MoneyMate. All rights reserved.\nDeveloped by Pranto Baidya.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(fontSize: 13),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    title,
                    style: theme.textTheme.titleMedium
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      tileColor: Colors.transparent,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}