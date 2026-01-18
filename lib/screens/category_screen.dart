import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/models/category_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/riverpod/premade_categories/premade_categories.dart';
import 'package:expense_tracker_app/screens/accounts_screen.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/listAnimation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../riverpod/currency_riverpod/currency_pref.dart';
import '../riverpod/prefs_riverpod/prefs_riverpod.dart';
import '../widgets/account_dashboard.dart';

enum CategoryType{income,expense}

final iconIndexProvider = StateProvider<int>((ref)=>0);

final selectedProvider = StateProvider<Set<String>>((ref)=>{'income'});

final colorProvider = StateProvider<Color>((ref)=>AppColors.mainColor);

final colorCodeProvider = StateProvider<String>((ref)=>'');

final colorPickerCheck = StateProvider<bool>((ref)=>false);

final colorPickerCheckFromDefault = StateProvider<int>((ref)=>0);

final iconCodeProvider = StateProvider<int>((ref)=>0);

final categoryTypeProvider = StateProvider<CategoryType>((ref)=>CategoryType.income);

final colorPickedFromPickerProvider = StateProvider<bool>((ref)=>false);

final checkCategoryTypingProvider = StateProvider<bool>((ref)=>false);

final editCategoryProvider = StateProvider<bool>((ref)=>false);

final selectedCategoryIdsProvider = StateProvider<Set<int>>((ref)=>{});

final isCategoryIdsSelectedForBulkDeleteProvider = StateProvider<bool>((ref)=>false);

final categoryDashboardCollapseProvider = StateProvider<bool>((ref)=>false);

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> with TickerProviderStateMixin {

  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;

  late Animation<Offset> _fabAnimation;

  late AnimationController _bulkDeleteFABController;

  late Animation<double> _bulkDeleteFABAnimation;

  late AnimationController _categoryBottomSheetAnimationController;

  late Animation<double> _bounceAnimation;

  double _lastScrollPosition = 0;

  bool _isFABVisible = true;

  final double _expandedHeight = 244.0.h;
  final double _collapsedHeight = 60.0.h;

  @override
  void initState() {

    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    _fabAnimation = Tween<Offset>(begin: Offset.zero,end: Offset(0, 1.5)).animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn));

    _bulkDeleteFABController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500)
    );

    _bulkDeleteFABAnimation = Tween<double>(begin: 0,end: 1).animate(CurvedAnimation(parent: _bulkDeleteFABController, curve: Curves.fastOutSlowIn));

    _categoryBottomSheetAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600)
    );

    _bounceAnimation = Tween<double>(begin: 0.5,end: 1).animate(CurvedAnimation(parent: _categoryBottomSheetAnimationController, curve: Curves.elasticOut));

    _nameController.addListener(()=>checkTyping(ref));
    
    WidgetsBinding.instance.addPostFrameCallback((_)async{
      await ref.read(preMadeCategoryProvider.notifier).initializePreMadeCategories(ref);
      ref.read(categoryProvider.notifier).getAllCategories();
    });
    super.initState();
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _editNameController = TextEditingController();


  List<Color> colors = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF84CC16),
    Color(0xFF22C55E),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFD946EF),
    Color(0xFFEC4899),
    Color(0xFFA855F7),
    Color(0xFF4ADE80),
    Color(0xFFFB7185),
    Color(0xFF5EEAD4),
    Color(0xFFFBCFE8),
    Color(0xFF94A3B8),
  ];

  bool isDuplicateCategory(CategoryModel category, WidgetRef ref){
    final categories = ref.read(categoryProvider);
    return categories.allCategories.any((cat) =>
    cat.categoryId != category.categoryId &&
        cat.categoryName.toLowerCase() == category.categoryName.toLowerCase() &&
        cat.color.value == category.color.value &&
        cat.icon.codePoint == category.icon.codePoint &&
        cat.categoryType == category.categoryType
    );
  }

  bool _handleFabButton(ScrollNotification scrollInfo){
    if(scrollInfo is ScrollUpdateNotification){

      final currentScrollPosition = scrollInfo.metrics.pixels;
      final scrollDelta = currentScrollPosition - _lastScrollPosition;

      if(scrollDelta>2 && _isFABVisible){
        _animationController.forward();
        _isFABVisible = false;
      }
      else if(scrollDelta<-2 && !_isFABVisible){
        _animationController.reverse();
        _isFABVisible = true;
      }

      _lastScrollPosition = currentScrollPosition;
    }
    return false;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _editNameController.dispose();
    _scrollController.removeListener(()=>_onScroll());
    _scrollController.dispose();
    _categoryBottomSheetAnimationController.dispose();
    super.dispose();
  }

  void _onScroll(){
    final collapseState = ref.read(categoryDashboardCollapseProvider);
    final collapseNotifier = ref.read(categoryDashboardCollapseProvider.notifier);

    final isCollapsed = _scrollController.offset > 50;

    if(isCollapsed!=collapseState){
      collapseNotifier.state = collapseState;
    }
  }

  void showDuplicateDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.error_outline,color: theme.colorScheme.primary,),
            ),
            SizedBox(width: 12.w,),
            Text(
              'Duplicate category',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A category with this data already exists',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 5.h,),
            Text('Please choose a different name or icon or color or type.',style: theme.textTheme.bodyMedium,)
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: ()=>Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: Size(420, 50),
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))
              ),
              child: Text('Okay',style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),),
          )
        ],
      ),
    );
  }

  void checkTyping(WidgetRef ref,{CategoryModel? category}){
    final isTyping = ref.read(checkCategoryTypingProvider);
    final isEditing = ref.read(editCategoryProvider);

    if(isEditing && category!=null) {
      bool hasChanged = _editNameController.text != category.categoryName
          || ref.read(iconCodeProvider) != category.icon.codePoint
          || ref.read(colorProvider).value != category.color.value
          || ref.read(categoryTypeProvider) != category.categoryType;

      if(hasChanged!=isTyping){
        ref.read(checkCategoryTypingProvider.notifier).state = hasChanged;
        return;
      }
    }
    else if(!isEditing){
      bool hasContents = _nameController.text.isNotEmpty && ref.read(iconCodeProvider)!=0;

      if(hasContents!=isTyping){
        ref.read(checkCategoryTypingProvider.notifier).state = hasContents;
      }
    }

  }

  void pickColorDialogue({CategoryModel? category}){
    showDialog(
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
              builder: (context,ref,_){

                final selectedColor = ref.watch(colorProvider);
                final isColorPickedFromPickerNotifier = ref.read(colorPickedFromPickerProvider.notifier);

                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title: Row(
                    children: [
                      Text('Pick a color',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
                      Spacer(),
                      IconButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close,color: theme.colorScheme.primary,size: 30,)
                      )
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        ref.read(colorProvider.notifier).state = color;
                        ref.read(colorCodeProvider.notifier).state = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
                        ref.read(colorPickerCheck.notifier).state = true;
                        isColorPickedFromPickerNotifier.state = true;
                        final isEditing = ref.read(editCategoryProvider);
                        if (isEditing) {
                          checkTyping(ref, category: category);
                        } else {
                          checkTyping(ref);
                        }
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        child: Text('Done',style: theme.textTheme.titleSmall,)
                    )
                  ],
                );
              }
          );
        }
    );
  }

  void addCategory(){
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useSafeArea: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
              ),
              child: Consumer(
                  builder: (context,ref,_){
                    List<IconData> icons = [
                      Icons.attach_money,
                      Icons.account_balance,
                      Icons.account_balance_wallet,
                      Icons.savings,
                      Icons.sanitizer_outlined,
                      Icons.photo,
                      Icons.money_off,
                      Icons.credit_card,
                      Icons.wallet,
                      Icons.payment,
                      Icons.request_page,
                      Icons.shopping_cart,
                      Icons.shopping_bag,
                      Icons.baby_changing_station,
                      Icons.fastfood,
                      Icons.local_cafe,
                      Icons.flight_takeoff,
                      Icons.directions_car,
                      Icons.home,
                      Icons.deck_outlined,
                      Icons.receipt_long,
                      Icons.lightbulb,
                      Icons.wifi,
                      Icons.phone_android,
                      Icons.medical_services,
                      Icons.health_and_safety,
                      Icons.movie,
                      Icons.sports_esports,
                      Icons.checkroom,
                      Icons.school,
                      Icons.pets,
                      Icons.celebration,
                      Icons.flight,
                      Icons.spa,
                      Icons.brush,
                      Icons.cleaning_services,
                      Icons.subscriptions,
                      Icons.sports_bar,
                      Icons.sports_cricket,
                      Icons.currency_bitcoin,
                      Icons.show_chart,
                    ].toSet().toList();

                    final isIconSelected =ref.watch(iconIndexProvider);

                    final iconNotifier = ref.read(iconIndexProvider.notifier);

                    final selected = ref.watch(selectedProvider);

                    final selectedNotifier = ref.read(selectedProvider.notifier);

                    final isColorPickedFromPicker = ref.watch(colorPickedFromPickerProvider);

                    final isColorPickedFromPickerNotifier = ref.read(colorPickedFromPickerProvider.notifier);

                    final hex = isColorPickedFromPicker? ref.watch(colorProvider).value.toRadixString(16).padLeft(8, '0'):ref.watch(colorProvider).value.toRadixString(16).padLeft(8, '0');

                    final rgb = hex.substring(2, 8);

                    final isColorPickedFromDefault = ref.watch(colorPickerCheckFromDefault);

                    final defaultColorNotifier = ref.read(colorPickerCheckFromDefault.notifier);

                    final categoryType = ref.watch(categoryTypeProvider);

                    final categoryTypeNotifier = ref.read(categoryTypeProvider.notifier);

                    final isTyping = ref.watch(checkCategoryTypingProvider);

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: theme.dividerColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Text(
                            'Add new category',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 24.h,),
                          TextFormField(
                            autofocus: true,
                            controller: _nameController,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Category Name',
                              hintText: 'Enter a category name',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.hintTextColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h,),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category,
                                        size: 20,
                                        color: theme.iconTheme.color?.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Choose icon',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Container(
                                    height: 60.h,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: icons.length,
                                      itemBuilder: (context, index) {
                                        final icon = icons[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: IconButton(
                                            onPressed: () {
                                              iconNotifier.state = index;
                                              ref.read(iconCodeProvider.notifier).state = icon.codePoint;
                                              checkTyping(ref);
                                            },
                                            icon: Icon(
                                              icon,
                                              color: isIconSelected == index
                                                  ? theme.colorScheme.primary
                                                  : theme.iconTheme.color?.withOpacity(0.7),
                                              size: 28,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h,),
                          Row(
                            children: ['income', 'expense'].map((type) {
                              final isSelected = selected.contains(type);
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: type == 'expense' ? 0 : 8,
                                    left: type == 'income' ? 0 : 8,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      selectedNotifier.state = {type};
                                      categoryTypeNotifier.state = type == 'income' ? CategoryType.income : CategoryType.expense;
                                      checkTyping(ref);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isSelected ? type == 'expense' ? Colors.redAccent : Colors.green : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? type == 'expense' ? Colors.redAccent : Colors.green : theme.dividerColor,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          isSelected ? type == 'expense' ? Icon(Icons.arrow_downward_outlined, color: Colors.white,) : Icon(Icons.arrow_upward_outlined, color: Colors.white,) : SizedBox.shrink(),
                                          SizedBox(width: 5.w,),
                                          Text(
                                            type == 'expense' ? 'Expense' : 'Income',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 20.h,),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.palette,
                                        size: 20,
                                        color: theme.iconTheme.color?.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Choose background color',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  Container(
                                    height: 50.h,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: colors.length,
                                      itemBuilder: (context, index) {
                                        final value = colors[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 12.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              defaultColorNotifier.state = index;
                                              ref.read(colorProvider.notifier).state = value;
                                              ref.read(colorCodeProvider.notifier).state = value.value.toRadixString(16).padLeft(8, '0').toUpperCase();
                                              ref.read(colorPickerCheck.notifier).state = true;
                                              isColorPickedFromPickerNotifier.state = false;
                                              checkTyping(ref);
                                            },
                                            child: CircleAvatar(
                                              radius: 22,
                                              backgroundColor: value,
                                              child: isColorPickedFromPicker ? SizedBox.shrink() : isColorPickedFromDefault == index ? Icon(Icons.check, color: Colors.white, size: 20) : SizedBox.shrink(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Divider(),
                                  SizedBox(height: 12.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Or pick a custom color',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          pickColorDialogue();
                                        },
                                        icon: Icon(
                                          Icons.colorize,
                                          color: theme.colorScheme.primary,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Visibility(
                                    visible: ref.watch(colorPickerCheck),
                                    replacement: SizedBox.shrink(),
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Selected: ',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          Text(
                                            '#${rgb}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Spacer(),
                                          IconButton(
                                            onPressed: () {
                                              final code = ref.watch(colorCodeProvider);
                                              Clipboard.setData(ClipboardData(text: code));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Copied to clipboard')),
                                              );
                                            },
                                            icon: Icon(Icons.copy, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h,),
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: !isTyping?
                            ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Add category',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withOpacity(0.38),
                                ),
                              ),
                            )
                                :ElevatedButton(
                              onPressed: () {
                                final category = CategoryModel(
                                  categoryName: _nameController.text,
                                  icon: IconData(
                                    ref.read(iconCodeProvider),
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  categoryType: categoryType,
                                  color: ref.read(colorProvider),
                                );

                                if (isDuplicateCategory(category, ref)) {
                                  showDuplicateDialog(context);
                                  return;
                                }

                                ref.read(categoryProvider.notifier).addCategory(category);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                backgroundColor: theme.colorScheme.primary,
                              ),
                              child: Text(
                                'Add category',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          ),
                          SizedBox(height: 20.h,),
                        ],
                      ),
                    );
                  }
              ),
            ),
          );
        }
    ).then((_){
      ref.read(colorCodeProvider.notifier).state = '';
      ref.read(colorPickerCheck.notifier).state = false;
      _nameController.clear();
      ref.read(iconIndexProvider.notifier).state = 0;
      ref.read(iconIndexProvider.notifier).state = 0;
      ref.read(checkCategoryTypingProvider.notifier).state = false;
    });
  }

  void editCategory(CategoryModel category){
    ref.read(editCategoryProvider.notifier).state = true;
    int? id = category.categoryId;
    _editNameController.text = category.categoryName;
    ref.read(iconCodeProvider.notifier).state = category.icon.codePoint;

    List<IconData> icons = [
      Icons.attach_money,
      Icons.account_balance,
      Icons.account_balance_wallet,
      Icons.savings,
      Icons.sanitizer_outlined,
      Icons.photo,
      Icons.money_off,
      Icons.credit_card,
      Icons.wallet,
      Icons.payment,
      Icons.request_page,
      Icons.shopping_cart,
      Icons.shopping_bag,
      Icons.baby_changing_station,
      Icons.fastfood,
      Icons.local_cafe,
      Icons.flight_takeoff,
      Icons.directions_car,
      Icons.home,
      Icons.deck_outlined,
      Icons.receipt_long,
      Icons.lightbulb,
      Icons.wifi,
      Icons.phone_android,
      Icons.medical_services,
      Icons.health_and_safety,
      Icons.movie,
      Icons.sports_esports,
      Icons.checkroom,
      Icons.school,
      Icons.pets,
      Icons.celebration,
      Icons.flight,
      Icons.spa,
      Icons.brush,
      Icons.cleaning_services,
      Icons.subscriptions,
      Icons.sports_bar,
      Icons.sports_cricket,
      Icons.currency_bitcoin,
      Icons.show_chart,
    ].toSet().toList();

    int iconIndex = icons.indexWhere((icon) => icon.codePoint == category.icon.codePoint);
    if (iconIndex != -1) {
      ref.read(iconIndexProvider.notifier).state = iconIndex;
    }

    ref.read(colorProvider.notifier).state = category.color;

    int colorIndex = colors.indexWhere((color) => color.value == category.color.value);
    if (colorIndex != -1) {
      ref.read(colorPickerCheckFromDefault.notifier).state = colorIndex;
      ref.read(colorPickedFromPickerProvider.notifier).state = false;
    } else {
      ref.read(colorPickedFromPickerProvider.notifier).state = true;
    }

    ref.read(colorCodeProvider.notifier).state = category.color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    ref.read(colorPickerCheck.notifier).state = true;

    ref.read(categoryTypeProvider.notifier).state = category.categoryType;

    ref.read(selectedProvider.notifier).state = category.categoryType == CategoryType.income ? {'income'} : {'expense'};

    ref.read(checkCategoryTypingProvider.notifier).state = false;

    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useSafeArea: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
              ),
              child: Consumer(
                  builder: (context,ref,_){
                    List<IconData> icons = [
                      Icons.attach_money,
                      Icons.account_balance,
                      Icons.account_balance_wallet,
                      Icons.savings,
                      Icons.sanitizer_outlined,
                      Icons.photo,
                      Icons.money_off,
                      Icons.credit_card,
                      Icons.wallet,
                      Icons.payment,
                      Icons.request_page,
                      Icons.shopping_cart,
                      Icons.shopping_bag,
                      Icons.baby_changing_station,
                      Icons.fastfood,
                      Icons.local_cafe,
                      Icons.flight_takeoff,
                      Icons.directions_car,
                      Icons.home,
                      Icons.deck_outlined,
                      Icons.receipt_long,
                      Icons.lightbulb,
                      Icons.wifi,
                      Icons.phone_android,
                      Icons.medical_services,
                      Icons.health_and_safety,
                      Icons.movie,
                      Icons.sports_esports,
                      Icons.checkroom,
                      Icons.school,
                      Icons.pets,
                      Icons.celebration,
                      Icons.flight,
                      Icons.spa,
                      Icons.brush,
                      Icons.cleaning_services,
                      Icons.subscriptions,
                      Icons.sports_bar,
                      Icons.sports_cricket,
                      Icons.currency_bitcoin,
                      Icons.show_chart,
                    ].toSet().toList();

                    final isIconSelected =ref.watch(iconIndexProvider);

                    final iconNotifier = ref.read(iconIndexProvider.notifier);

                    final selected = ref.watch(selectedProvider);

                    final selectedNotifier = ref.read(selectedProvider.notifier);

                    final isColorPickedFromPicker = ref.watch(colorPickedFromPickerProvider);

                    final isColorPickedFromPickerNotifier = ref.read(colorPickedFromPickerProvider.notifier);

                    final hex = isColorPickedFromPicker? ref.watch(colorProvider).value.toRadixString(16).padLeft(8, '0'):ref.watch(colorProvider).value.toRadixString(16).padLeft(8, '0');

                    final rgb = hex.substring(2, 8);

                    final isColorPickedFromDefault = ref.watch(colorPickerCheckFromDefault);

                    final defaultColorNotifier = ref.read(colorPickerCheckFromDefault.notifier);

                    final categoryType = ref.watch(categoryTypeProvider);

                    final categoryTypeNotifier = ref.read(categoryTypeProvider.notifier);

                    final isTyping = ref.watch(checkCategoryTypingProvider);

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: theme.dividerColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Text(
                            'Edit category',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 24.h,),
                          TextFormField(
                            autofocus: true,
                            controller: _editNameController,
                            onChanged: (_) => checkTyping(ref,category: category),
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Category Name',
                              hintText: 'Enter a category name',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.hintTextColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h,),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category,
                                        size: 20,
                                        color: theme.iconTheme.color?.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Choose icon',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Container(
                                    height: 60.h,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: icons.length,
                                      itemBuilder: (context, index) {
                                        final icon = icons[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: IconButton(
                                            onPressed: () {
                                              iconNotifier.state = index;
                                              ref.read(iconCodeProvider.notifier).state = icon.codePoint;
                                              checkTyping(ref,category: category);
                                            },
                                            icon: Icon(
                                              icon,
                                              color: isIconSelected == index
                                                  ? theme.colorScheme.primary
                                                  : theme.iconTheme.color?.withOpacity(0.7),
                                              size: 28,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h,),
                          Row(
                            children: ['income', 'expense'].map((type) {
                              final isSelected = selected.contains(type);
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: type == 'expense' ? 0 : 8,
                                    left: type == 'income' ? 0 : 8,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      selectedNotifier.state = {type};
                                      categoryTypeNotifier.state = type == 'income' ? CategoryType.income : CategoryType.expense;
                                      checkTyping(ref,category: category);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isSelected ? type == 'expense' ? Colors.redAccent : Colors.green : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? type == 'expense' ? Colors.redAccent : Colors.green : theme.dividerColor,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          isSelected ? type == 'expense' ? Icon(Icons.arrow_downward_outlined, color: Colors.white,) : Icon(Icons.arrow_upward_outlined, color: Colors.white,) : SizedBox.shrink(),
                                          SizedBox(width: 5.w,),
                                          Text(
                                            type == 'expense' ? 'Expense' : 'Income',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 20.h,),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.palette,
                                        size: 20,
                                        color: theme.iconTheme.color?.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Choose background color',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  Container(
                                    height: 50.h,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: colors.length,
                                      itemBuilder: (context, index) {
                                        final value = colors[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 12.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              defaultColorNotifier.state = index;
                                              ref.read(colorProvider.notifier).state = value;
                                              ref.read(colorCodeProvider.notifier).state = value.value.toRadixString(16).padLeft(8, '0').toUpperCase();
                                              ref.read(colorPickerCheck.notifier).state = true;
                                              isColorPickedFromPickerNotifier.state = false;
                                              checkTyping(ref,category: category);
                                            },
                                            child: CircleAvatar(
                                              radius: 22,
                                              backgroundColor: value,
                                              child: isColorPickedFromPicker ? SizedBox.shrink() : isColorPickedFromDefault == index ? Icon(Icons.check, color: Colors.white, size: 20) : SizedBox.shrink(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Divider(),
                                  SizedBox(height: 12.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Or pick a custom color',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          pickColorDialogue(category: category);
                                        },
                                        icon: Icon(
                                          Icons.colorize,
                                          color: theme.colorScheme.primary,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Visibility(
                                    visible: ref.watch(colorPickerCheck),
                                    replacement: SizedBox.shrink(),
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Selected: ',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          Text(
                                            '#${rgb}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Spacer(),
                                          IconButton(
                                            onPressed: () {
                                              final code = ref.watch(colorCodeProvider);
                                              Clipboard.setData(ClipboardData(text: code));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Copied to clipboard')),
                                              );
                                            },
                                            icon: Icon(Icons.copy, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h,),
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: !isTyping?
                            ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Edit category',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withOpacity(0.38),
                                ),
                              ),
                            )
                                :ElevatedButton(
                              onPressed: () {
                                final updatedCategory = CategoryModel(
                                  categoryId: category.categoryId,
                                  categoryName: _editNameController.text,
                                  icon: IconData(
                                    ref.read(iconCodeProvider),
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  categoryType: categoryType,
                                  color: ref.read(colorProvider),
                                );

                                if (isDuplicateCategory(updatedCategory, ref)) {
                                  showDuplicateDialog(context);
                                  return;
                                }

                                ref.read(categoryProvider.notifier).updateCategory(updatedCategory);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                backgroundColor: theme.colorScheme.primary,
                              ),
                              child: Text(
                                'Edit category',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          ),
                          SizedBox(height: 20.h,),
                        ],
                      ),
                    );
                  }
              ),
            ),
          );
        }
    ).then((_){
      ref.read(editCategoryProvider.notifier).state = false;
      ref.read(checkCategoryTypingProvider.notifier).state = false;
    });
  }

  void categoryDetailsSheet(CategoryModel category) {
    _categoryBottomSheetAnimationController.reset();
    _categoryBottomSheetAnimationController.forward();

    bool isSortPressed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final theme = Theme.of(context);

            final records = ref
                .read(expenseProvider)
                .expenses
                .where((e) => e.category == category.categoryName)
                .toList();

            records.sort((a, b) => b.date.compareTo(a.date));

            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.92,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                        width: 46.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: theme.iconTheme.color,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),

                      SizedBox(height: 10.h),

                      ScaleTransition(
                        scale: _bounceAnimation,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 20.w),
                          padding: EdgeInsets.all(22.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28.r),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                category.color,
                                category.color.withOpacity(0.75),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: category.color.withOpacity(0.45),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64.w,
                                height: 64.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(22.r),
                                ),
                                child: Icon(
                                  category.icon,
                                  size: 32.sp,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 15.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.categoryName,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      category.categoryType.name.toUpperCase(),
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white70,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Container(
                          padding: EdgeInsets.all(18.w),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(22.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 14,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: category.color,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    records.isEmpty ? 'No transactions' : '${records.length} transactions',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'All time activity',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Visibility(
                        visible: records.isNotEmpty,
                        replacement: SizedBox.shrink(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Row(
                            children: [
                              Text(
                                'Transactions',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Visibility(
                                visible: records.length > 1,
                                replacement: SizedBox.shrink(),
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      isSortPressed = !isSortPressed;
                                      if (isSortPressed) {
                                        records.sort((a, b) => a.date.compareTo(b.date));
                                      } else {
                                        records.sort((a, b) => b.date.compareTo(a.date));
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                        color: theme.dividerColor.withOpacity(0.2),
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child, Animation<double> animation) {
                                        return ScaleTransition(scale: animation, child: child);
                                      },
                                      child: Icon(
                                        isSortPressed ? Icons.arrow_upward : Icons.arrow_downward,
                                        key: ValueKey<bool>(isSortPressed),
                                        color: theme.iconTheme.color,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Expanded(
                        child: records.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(28.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: category.color.withOpacity(0.12),
                                ),
                                child: Icon(
                                  Icons.inbox_rounded,
                                  size: 50.sp,
                                  color: category.color.withOpacity(0.6),
                                ),
                              ),
                              SizedBox(height: 18.h),
                              Text(
                                'No activity yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Transactions will appear here',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                            : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                          itemCount: records.length,
                          separatorBuilder: (_, __) => SizedBox(height: 14.h),
                          itemBuilder: (context, index) {
                            final data = records[index];

                            final account = ref.read(cardsProvider).cards.firstWhere(
                                  (i) => i.id == data.accountId,
                              orElse: () => CardModel(
                                cardName: 'Unknown',
                                amount: 0,
                                icon: Icons.error_outline,
                              ),
                            );

                            final formatted = NumberFormat.currency(
                              symbol: ref.read(newCurrencyProvider).currency,
                              decimalDigits: 2,
                            ).format(data.amount);

                            final isExpense = category.categoryType == CategoryType.expense;

                            return ListAnimationWidget(
                              index: index,
                              offset: Offset(0, 0.3),
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(15.r),
                                  border: Border(
                                    left: BorderSide(color: category.color, width: 5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46.w,
                                      height: 46.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: category.color.withOpacity(0.15),
                                      ),
                                      child: Icon(
                                        category.icon,
                                        color: category.color,
                                      ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                data.title,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Spacer(),
                                              Container(
                                                padding: EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: category.categoryType == CategoryType.expense
                                                        ? Colors.red
                                                        : Colors.green,
                                                    width: 1,
                                                  ),
                                                  color: category.categoryType == CategoryType.expense
                                                      ? Colors.red.withOpacity(0.08)
                                                      : Colors.green.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(10.r),
                                                ),
                                                child: Text(
                                                  '${isExpense ? '-' : '+'}$formatted',
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: isExpense ? Colors.red : Colors.green,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              Icon(account.icon, color: theme.iconTheme.color, size: 16),
                                              SizedBox(width: 4.w),
                                              Text(
                                                account.cardName,
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              Icon(Icons.watch_later_outlined, color: theme.iconTheme.color, size: 16),
                                              SizedBox(width: 4.w),
                                              Text(
                                                DateFormat('dd MMM yyyy, hh:mm a').format(data.date),
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      _categoryBottomSheetAnimationController.reset();
    });
  }

  void deleteAlert(CategoryModel cat){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete category',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete this category?\nThis action cannot be undone.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (){
                            ref.read(categoryProvider.notifier).deleteCategory(cat.categoryId!);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  void bulkDeleteAlert(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          final selectedIds = ref.read(selectedCategoryIdsProvider);
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: selectedIds.length==1?Text(
                          'Delete ${selectedIds.length} category?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 17,fontWeight: FontWeight.bold),
                        ):Text(
                          'Delete ${selectedIds.length} categories?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 17,fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This action cannot be undone.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (){
                            ref.read(categoryProvider.notifier).bulkDeleteCategories(selectedIds.toList());
                            selectedIds.clear();
                            ref.read(isCategoryIdsSelectedForBulkDeleteProvider.notifier).state = false;
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    final allCategorieState = ref.watch(categoryProvider);

    final incomeCategoryState = ref.watch(categoryProvider).allIncomeCategories;

    final expenseCategoryState = ref.watch(categoryProvider).allExpenseCategories;


    final cardState = ref.watch(cardsProvider);

    final totalAccountBalance = cardState.cards.fold(0.0, (sum,value)=>sum+value.amount);

    final avg = ref.watch(cardsProvider).cards.isEmpty ? 0.0 : ref.watch(cardsProvider).cards.fold(0.0, (sum, card) => sum + card.progress) / ref.watch(cardsProvider).cards.length;

    final isSelectedForBulkDelete = ref.watch(isCategoryIdsSelectedForBulkDeleteProvider);

    final isSelectedForBulkDeleteNotifier = ref.read(isCategoryIdsSelectedForBulkDeleteProvider.notifier);

    final selectedIdsState = ref.watch(selectedCategoryIdsProvider);

    final selectedIdsNotifier = ref.read(selectedCategoryIdsProvider.notifier);

    final isCollapseModeActivated = ref.watch(collapseDashboardPrefProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: isCollapseModeActivated? NotificationListener<ScrollNotification>(
        onNotification: _handleFabButton,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: _expandedHeight,
              collapsedHeight: _collapsedHeight,
              backgroundColor: theme.colorScheme.primary,
              elevation: 0,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxHeight = _expandedHeight;
                  final double minHeight = _collapsedHeight;
                  final double currentHeight = constraints.maxHeight;
                  final double collapseThreshold = minHeight + ((maxHeight - minHeight) * 0.3);
                  final bool isCurrentlyCollapsed = currentHeight <= collapseThreshold;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final currentState = ref.read(categoryDashboardCollapseProvider);
                    if (isCurrentlyCollapsed != currentState) {
                      ref.read(categoryDashboardCollapseProvider.notifier).state = isCurrentlyCollapsed;
                    }
                  });

                  return AnimatedAccountDashboard(isCollapsed: isCurrentlyCollapsed);
                },
              ),
            ),

            if(allCategorieState.isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child:
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
              )
            else...[
              if (incomeCategoryState.isEmpty && expenseCategoryState.isEmpty)...[
                SliverToBoxAdapter(
                  child: SizedBox(height: 12.h),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 80.h,),
                        Icon(Icons.folder_off_outlined, color: theme.colorScheme.primary, size: 100),
                        SizedBox(height: 24.h),
                        Text('No categories available', style: theme.textTheme.titleLarge),
                        SizedBox(height: 8.h),
                        Text('Add a category from the button below', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],

              if (incomeCategoryState.isNotEmpty || expenseCategoryState.isNotEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child:  Column(
                    children: [
                      SizedBox(height: 10.h),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 15.h),

                            if (incomeCategoryState.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Income categories',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            SizedBox(height: 10.h),

                            ...incomeCategoryState.map(
                                  (data) => GestureDetector(
                                onLongPress: () {
                                  isSelectedForBulkDeleteNotifier.state = true;
                                  selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(data.categoryId!);
                                  if (selectedIdsNotifier.state.length == 1) {
                                    _bulkDeleteFABController.forward(from: 0);
                                  }
                                },
                                onTap: () {
                                  if (selectedIdsNotifier.state.contains(data.categoryId)) {
                                    selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..remove(data.categoryId!);
                                    if (selectedIdsNotifier.state.isEmpty) {
                                      isSelectedForBulkDeleteNotifier.state = false;
                                      _bulkDeleteFABController.reverse();
                                    }
                                  } else {
                                    selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(data.categoryId!);
                                  }
                                },
                                child: Column(
                                  children: [
                                    if (isSelectedForBulkDelete) ...[
                                      Padding(
                                        padding: EdgeInsets.only(left: 20.w),
                                        child: Row(
                                          children: [
                                            Icon(
                                              selectedIdsState.contains(data.categoryId) ? Icons.check_box : Icons.check_box_outline_blank,
                                              color: selectedIdsState.contains(data.categoryId) ? theme.colorScheme.primary : Colors.grey,
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: theme.cardColor.withOpacity(0.92),
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
                                                    ]
                                                        : [
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
                                                  child: ListTile(
                                                    tileColor: Colors.transparent,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    leading: Container(
                                                      width: 45.w,
                                                      height: 45.h,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(14.r),
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            data.color.withOpacity(0.9),
                                                            data.color.withOpacity(0.6),
                                                          ],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: data.color.withOpacity(0.3),
                                                            blurRadius: 12,
                                                            spreadRadius: 1,
                                                            offset: const Offset(0, 4),
                                                          )
                                                        ],
                                                      ),
                                                      child: Icon(data.icon, color: Colors.white, size: 24),
                                                    ),
                                                    title: Text(
                                                      data.categoryName,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (!isSelectedForBulkDelete) ...[
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                        child: ListAnimationWidget(
                                          offset: Offset(0, 0.3),
                                          index: incomeCategoryState.indexOf(data),
                                          child: GestureDetector(
                                            onTap: () => categoryDetailsSheet(data),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: theme.cardColor.withOpacity(0.92),
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
                                                ]
                                                    : [
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
                                              child: ListTile(
                                                tileColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: Container(
                                                  width: 45.w,
                                                  height: 45.h,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(14.r),
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        data.color.withOpacity(0.9),
                                                        data.color.withOpacity(0.6),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: data.color.withOpacity(0.3),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                        offset: const Offset(0, 4),
                                                      )
                                                    ],
                                                  ),
                                                  child: Icon(data.icon, color: Colors.white, size: 24),
                                                ),
                                                title: Text(
                                                  data.categoryName,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                trailing: Container(
                                                  decoration: BoxDecoration(
                                                    color: theme.cardColor.withOpacity(0.5),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: PopupMenuButton(
                                                    color: theme.cardColor,
                                                    elevation: 8,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    icon: Icon(Icons.more_horiz, size: 20),
                                                    menuPadding: EdgeInsets.all(5),
                                                    onSelected: (value) {
                                                      if(value=='details'){
                                                        categoryDetailsSheet(data);
                                                      }
                                                      else if (value == "edit") {
                                                        editCategory(data);
                                                      }
                                                      else if (value == "delete") {
                                                        deleteAlert(data);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                          value: 'details',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.info_outlined, size: 18,color: data.color,),
                                                              SizedBox(width: 12),
                                                              Text("Details", style: theme.textTheme.titleSmall?.copyWith(color: data.color)),
                                                            ],
                                                          )
                                                      ),
                                                      PopupMenuItem(
                                                        value: "edit",
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit_outlined, size: 18),
                                                            SizedBox(width: 12),
                                                            Text("Edit", style: theme.textTheme.titleSmall),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: "delete",
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                            SizedBox(width: 12),
                                                            Text(
                                                              "Delete",
                                                              style: theme.textTheme.titleSmall?.copyWith(
                                                                color: Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 30),

                            if (expenseCategoryState.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Expense categories',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            SizedBox(height: 10.h),

                            ...expenseCategoryState.map(
                                  (data) => GestureDetector(
                                onLongPress: () {
                                  isSelectedForBulkDeleteNotifier.state = true;
                                  selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(data.categoryId!);
                                  if (selectedIdsNotifier.state.length == 1) {
                                    _bulkDeleteFABController.forward(from: 0);
                                  }
                                },
                                onTap: () {
                                  if (selectedIdsNotifier.state.contains(data.categoryId)) {
                                    selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..remove(data.categoryId!);
                                    if (selectedIdsNotifier.state.isEmpty) {
                                      isSelectedForBulkDeleteNotifier.state = false;
                                      _bulkDeleteFABController.reverse();
                                    }
                                  } else {
                                    selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(data.categoryId!);
                                  }
                                },
                                child: Column(
                                  children: [
                                    if (isSelectedForBulkDelete) ...[
                                      Padding(
                                        padding: EdgeInsets.only(left: 20.w),
                                        child: Row(
                                          children: [
                                            Icon(
                                              selectedIdsState.contains(data.categoryId) ? Icons.check_box : Icons.check_box_outline_blank,
                                              color: selectedIdsState.contains(data.categoryId) ? theme.colorScheme.primary : Colors.grey,
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: theme.cardColor.withOpacity(0.92),
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
                                                    ]
                                                        : [
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
                                                  child: ListTile(
                                                    tileColor: Colors.transparent,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    leading: Container(
                                                      width: 45.w,
                                                      height: 45.h,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(14.r),
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            data.color.withOpacity(0.9),
                                                            data.color.withOpacity(0.6),
                                                          ],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: data.color.withOpacity(0.3),
                                                            blurRadius: 12,
                                                            spreadRadius: 1,
                                                            offset: const Offset(0, 4),
                                                          )
                                                        ],
                                                      ),
                                                      child: Icon(data.icon, color: Colors.white, size: 24),
                                                    ),
                                                    title: Text(
                                                      data.categoryName,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (!isSelectedForBulkDelete) ...[
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                        child: ListAnimationWidget(
                                          offset: Offset(0, 0.3),
                                          index: expenseCategoryState.indexOf(data),
                                          child: GestureDetector(
                                            onTap: () => categoryDetailsSheet(data),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: theme.cardColor.withOpacity(0.92),
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
                                                ]
                                                    : [
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
                                              child: ListTile(
                                                tileColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: Container(
                                                  width: 45.w,
                                                  height: 45.h,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(14.r),
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        data.color.withOpacity(0.9),
                                                        data.color.withOpacity(0.6),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: data.color.withOpacity(0.3),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                        offset: const Offset(0, 4),
                                                      )
                                                    ],
                                                  ),
                                                  child: Icon(data.icon, color: Colors.white, size: 24),
                                                ),
                                                title: Text(
                                                  data.categoryName,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                trailing: Container(
                                                  decoration: BoxDecoration(
                                                    color: theme.cardColor.withOpacity(0.5),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: PopupMenuButton(
                                                    color: theme.cardColor,
                                                    elevation: 8,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    icon: Icon(Icons.more_horiz, size: 20),
                                                    menuPadding: EdgeInsets.all(5),
                                                    onSelected: (value) {
                                                      if(value=='details'){
                                                        categoryDetailsSheet(data);
                                                      }
                                                      else if (value == "edit") {
                                                        editCategory(data);
                                                      } else if (value == "delete") {
                                                        deleteAlert(data);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                          value: 'details',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.info_outlined, size: 18,color: data.color,),
                                                              SizedBox(width: 12),
                                                              Text("Details", style: theme.textTheme.titleSmall?.copyWith(color: data.color)),
                                                            ],
                                                          )
                                                      ),
                                                      PopupMenuItem(
                                                        value: "edit",
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit_outlined, size: 18),
                                                            SizedBox(width: 12),
                                                            Text("Edit", style: theme.textTheme.titleSmall),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: "delete",
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                            SizedBox(width: 12),
                                                            Text(
                                                              "Delete",
                                                              style: theme.textTheme.titleSmall?.copyWith(
                                                                color: Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 15.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
            ]
          ],
        ),
      )
      :Column(
        children: [
          AccountDashboard(
              avgUsage: avg,
              totalBalance: totalAccountBalance,
              theme: theme,
              selectedCurrency: ref.watch(newCurrencyProvider).currency
          ),
          SizedBox(height: 10.h,),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: allCategorieState.isLoading?
              Center(child: CircularProgressIndicator(color: theme.colorScheme.primary,),)
                  :NotificationListener(
                onNotification: _handleFabButton,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if(incomeCategoryState.isEmpty && expenseCategoryState.isEmpty)...[
                        Column(
                          children: [
                            SizedBox(height: 80.h),
                            Icon(Icons.folder_off_outlined, color: theme.colorScheme.primary, size: 100),
                            SizedBox(height: 24.h),
                            Text('No categories available', style: theme.textTheme.titleLarge),
                            SizedBox(height: 8.h),
                            Text('Add a category from the button below', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ],

                      SizedBox(height: 15.h,),
                      Visibility(
                        visible: incomeCategoryState.isNotEmpty,
                        replacement: SizedBox.shrink(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Income categories',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),

                      ...incomeCategoryState.map((data) =>
                          GestureDetector(
                            onLongPress: (){
                              isSelectedForBulkDeleteNotifier.state = true;
                              selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(data.categoryId!);
                              if(selectedIdsNotifier.state.length==1) {
                                _bulkDeleteFABController.forward(from: 0);
                              }
                            },
                            onTap: (){
                              if(selectedIdsNotifier.state.contains(data.categoryId)){
                                selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..remove(data.categoryId!);
                                if(selectedIdsNotifier.state.isEmpty){
                                  isSelectedForBulkDeleteNotifier.state = false;
                                  _bulkDeleteFABController.reverse();
                                }
                              }
                              else{
                                selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(data.categoryId!);
                              }
                            },
                            child: Column(
                              children: [
                                if(isSelectedForBulkDelete)...[
                                  Padding(
                                    padding: EdgeInsets.only(left: 20.w),
                                    child: Row(
                                      children: [
                                        Icon(
                                          selectedIdsState.contains(data.categoryId)?Icons.check_box:Icons.check_box_outline_blank,
                                          color: selectedIdsState.contains(data.categoryId)? theme.colorScheme.primary:Colors.grey,
                                        ),
                                        SizedBox(width: 10.w,),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: theme.cardColor.withOpacity(0.92),
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
                                              child: ListTile(
                                                tileColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: Container(
                                                  width: 45.w,
                                                  height: 45.h,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(14.r),
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        data.color.withOpacity(0.9),
                                                        data.color.withOpacity(0.6),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: data.color.withOpacity(0.3),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                        offset: const Offset(0, 4),
                                                      )
                                                    ],
                                                  ),
                                                  child: Icon(data.icon, color: Colors.white, size: 24),
                                                ),
                                                title: Text(
                                                  data.categoryName,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),],
                                if(!isSelectedForBulkDelete)...[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                    child: ListAnimationWidget(
                                      offset: Offset(0, 0.3),
                                      index: incomeCategoryState.indexOf(data),
                                      child: GestureDetector(
                                        onTap: ()=>categoryDetailsSheet(data),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: theme.cardColor.withOpacity(0.92),
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
                                          child: ListTile(
                                            tileColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: Container(
                                              width: 45.w,
                                              height: 45.h,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(14.r),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    data.color.withOpacity(0.9),
                                                    data.color.withOpacity(0.6),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: data.color.withOpacity(0.3),
                                                    blurRadius: 12,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 4),
                                                  )
                                                ],
                                              ),
                                              child: Icon(data.icon, color: Colors.white, size: 24),
                                            ),
                                            title: Text(
                                              data.categoryName,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            trailing: Container(
                                              decoration: BoxDecoration(
                                                color: theme.cardColor.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: PopupMenuButton(
                                                color: theme.cardColor,
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                icon: Icon(Icons.more_horiz, size: 20),
                                                menuPadding: EdgeInsets.all(5),
                                                onSelected: (value) {
                                                  if(value=='details'){
                                                    categoryDetailsSheet(data);
                                                  }
                                                  else if (value == "edit") {
                                                    editCategory(data);
                                                  }
                                                  else if (value == "delete") {
                                                    deleteAlert(data);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: "details",
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.info_outlined, size: 18,color: data.color,),
                                                        SizedBox(width: 12),
                                                        Text("Details", style: theme.textTheme.titleSmall?.copyWith(color: data.color)),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: "edit",
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, size: 18),
                                                        SizedBox(width: 12),
                                                        Text("Edit", style: theme.textTheme.titleSmall),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: "delete",
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                        SizedBox(width: 12),
                                                        Text(
                                                          "Delete",
                                                          style: theme.textTheme.titleSmall?.copyWith(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ],
                            ),
                          )
                      ),

                      SizedBox(height: 30),

                      Visibility(
                        visible: expenseCategoryState.isNotEmpty,
                        replacement: SizedBox.shrink(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Expense categories',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),

                      ...expenseCategoryState.map((data) => GestureDetector(
                        onLongPress: (){
                          isSelectedForBulkDeleteNotifier.state = true;
                          selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(data.categoryId!);
                          if(selectedIdsNotifier.state.length==1) {
                            _bulkDeleteFABController.forward(from: 0);
                          }
                        },
                        onTap: (){
                          if(selectedIdsNotifier.state.contains(data.categoryId)){
                            selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..remove(data.categoryId!);
                            if(selectedIdsNotifier.state.isEmpty){
                              isSelectedForBulkDeleteNotifier.state = false;
                              _bulkDeleteFABController.reverse();
                            }
                          }
                          else{
                            selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(data.categoryId!);
                          }
                        },
                        child: Column(
                          children: [
                            if(isSelectedForBulkDelete)...[
                              Padding(
                                padding: EdgeInsets.only(left: 20.w),
                                child: Row(
                                  children: [
                                    Icon(
                                      selectedIdsState.contains(data.categoryId)?Icons.check_box:Icons.check_box_outline_blank,
                                      color: selectedIdsState.contains(data.categoryId)? theme.colorScheme.primary:Colors.grey,
                                    ),
                                    SizedBox(width: 10.w,),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: theme.cardColor.withOpacity(0.92),
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
                                          child: ListTile(
                                            tileColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            leading: Container(
                                              width: 45.w,
                                              height: 45.h,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(14.r),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    data.color.withOpacity(0.9),
                                                    data.color.withOpacity(0.6),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: data.color.withOpacity(0.3),
                                                    blurRadius: 12,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 4),
                                                  )
                                                ],
                                              ),
                                              child: Icon(data.icon, color: Colors.white, size: 24),
                                            ),
                                            title: Text(
                                              data.categoryName,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),],
                            if(!isSelectedForBulkDelete)...[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                child: ListAnimationWidget(
                                  offset: Offset(0, 0.3),
                                  index: expenseCategoryState.indexOf(data),
                                  child: GestureDetector(
                                    onTap: ()=>categoryDetailsSheet(data),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.cardColor.withOpacity(0.92),
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
                                      child: ListTile(
                                        tileColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: Container(
                                          width: 45.w,
                                          height: 45.h,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14.r),
                                            gradient: LinearGradient(
                                              colors: [
                                                data.color.withOpacity(0.9),
                                                data.color.withOpacity(0.6),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: data.color.withOpacity(0.3),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 4),
                                              )
                                            ],
                                          ),
                                          child: Icon(data.icon, color: Colors.white, size: 24),
                                        ),
                                        title: Text(
                                          data.categoryName,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing: Container(
                                          decoration: BoxDecoration(
                                            color: theme.cardColor.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: PopupMenuButton(
                                            color: theme.cardColor,
                                            elevation: 8,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            icon: Icon(Icons.more_horiz, size: 20),
                                            menuPadding: EdgeInsets.all(5),
                                            onSelected: (value) {
                                              if(value=='details'){
                                                categoryDetailsSheet(data);
                                              }
                                              else if (value == "edit") {
                                                editCategory(data);
                                              }
                                              else if (value == "delete") {
                                                deleteAlert(data);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: "details",
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outlined, size: 18,color: data.color,),
                                                    SizedBox(width: 12),
                                                    Text("Details", style: theme.textTheme.titleSmall?.copyWith(color: data.color)),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: "edit",
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, size: 18),
                                                    SizedBox(width: 12),
                                                    Text("Edit", style: theme.textTheme.titleSmall),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: "delete",
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      "Delete",
                                                      style: theme.textTheme.titleSmall?.copyWith(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ],
                        ),
                      )),
                      SizedBox(height: 10.h,),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),

      floatingActionButton: isSelectedForBulkDelete?
      ScaleTransition(
        scale: _bulkDeleteFABAnimation,
        child: Container(
          height: 64.h,
          width: 64.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.9),
                Colors.red.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: bulkDeleteAlert,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      )
      :SlideTransition(
        position: _fabAnimation,
        child: Container(
          height: 64.h,
          width: 64.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.9),
                theme.colorScheme.primary.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: addCategory,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: Icon(
                  Icons.sell,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


}
