import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/models/category_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/riverpod/premade_categories/premade_categories.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../riverpod/currency_riverpod/currency_pref.dart';
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

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> with TickerProviderStateMixin {

  late AnimationController _animationController;

  late Animation<Offset> _fabAnimation;

  late AnimationController _bulkDeleteFABController;

  late Animation<double> _bulkDeleteFABAnimation;

  double _lastScrollPosition = 0;

  bool _isFABVisible = true;

  @override
  void initState() {

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

  bool _handleFabButton(ScrollNotification scrollInfo){
    if(scrollInfo is ScrollUpdateNotification){

      final currentScrollPosition = scrollInfo.metrics.pixels;
      final scrollDelta = currentScrollPosition - _lastScrollPosition;

      if(scrollDelta>8 && _isFABVisible){
        _animationController.forward();
        _isFABVisible = false;
      }
      else if(scrollDelta<-8 && !_isFABVisible){
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
    super.dispose();
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
        backgroundColor: Theme.of(context).cardColor,
        showDragHandle: true,
        isScrollControlled: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
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

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    width: double.infinity.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h,),
                          Text('Add new category',style: theme.textTheme.titleLarge,),
                          SizedBox(height: 15.h,),
                          TextField(
                            autofocus: true,
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter a category name',
                              hintStyle: theme.textTheme.labelLarge?.copyWith(color: AppColors.hintTextColor)
                            ),
                          ),
                          SizedBox(height: 15.h,),
                          Text('Choose icon',style: theme.textTheme.titleMedium,),
                          SizedBox(height: 10.h,),
                          Container(
                              height: 80.h,
                              decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...icons.asMap().entries.map((i) {
                                      final index = i.key;
                                      final icon = i.value;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: IconButton(
                                          onPressed: () {
                                            iconNotifier.state = index;
                                            ref.read(iconCodeProvider.notifier).state = icon.codePoint;
                                            checkTyping(ref);
                                          },
                                          icon: isIconSelected == index
                                              ? Icon(icon, color: theme.colorScheme.primary, size: 30)
                                              : Icon(icon, color: theme.iconTheme.color, size: 30),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 15.h,),
                          Text('Choose category type',style: theme.textTheme.titleMedium,),
                          SizedBox(height: 10.h,),
                          SizedBox(
                            width: double.infinity.w,
                            height: 45.h,
                            child: SegmentedButton(
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith((state){
                                    if(state.contains(WidgetState.selected)){
                                      return selected.contains('expense')? Colors.redAccent : Colors.green;
                                    }
                                    return Colors.transparent;
                                  }),

                                  foregroundColor: WidgetStateProperty.resolveWith((state){
                                    if(state.contains(WidgetState.selected)){
                                      return Colors.white;
                                    }
                                    return theme.colorScheme.onSurface;
                                  }),
                                  
                                  side: WidgetStatePropertyAll(BorderSide(color: theme.dividerColor.withOpacity(0.3)))
                                ),
                                segments: [
                                  ButtonSegment(
                                      value: 'income',
                                      label: Text('Income')
                                  ),
                                  ButtonSegment(
                                      value: 'expense',
                                      label: Text('Expense')
                                  ),
                                ],
                                
                                selected: selected,
                                onSelectionChanged: (Set<String> newSelection){
                                  selectedNotifier.state = newSelection;
                                  categoryTypeNotifier.state = newSelection.first=='income'? CategoryType.income : CategoryType.expense;
                                  checkTyping(ref);
                                },
                            ),
                          ),
                          SizedBox(height: 15.h,),
                          Text('Choose background color',style: theme.textTheme.titleMedium,),
                          SizedBox(height: 10.h,),
                          Container(
                                height: 240.h,
                                decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 15.h,),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          ...colors.asMap().entries.map((i){
                                            final index = i.key;
                                            final value = i.value;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                                  radius: 20,
                                                  backgroundColor: value,
                                                  child: isColorPickedFromPicker?SizedBox.shrink():isColorPickedFromDefault==index?Icon(Icons.check,color: Colors.white,):SizedBox.shrink(),
                                                ),
                                              ),
                                            );
                                          })
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20.h,),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 100),
                                      child: Text('Or, Pick a custom color',style: theme.textTheme.titleMedium,),
                                    ),
                                    SizedBox(height: 10.h,),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 150),
                                      child: IconButton(
                                          onPressed: (){
                                            pickColorDialogue();
                                          },
                                          icon: Icon(Icons.colorize,color: theme.iconTheme.color,size: 60,)
                                      ),
                                    ),
                                    Visibility(
                                      visible: ref.watch(colorPickerCheck),
                                      replacement: SizedBox.shrink(),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 22),
                                        child: Row(
                                          children: [
                                            Text('Selected color code : ',style: theme.textTheme.titleMedium),
                                            SizedBox(width: 5.w,),
                                            Text('#${rgb}',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),),
                                            IconButton(
                                                onPressed: (){
                                                  final code = ref.watch(colorCodeProvider);
                                                  Clipboard.setData(ClipboardData(text: code));

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Copied to clipboard')),
                                                  );
                                                },
                                                icon: Icon(Icons.copy,color: theme.iconTheme.color,)
                                            )
                                          ],

                                        ),
                                      ),
                                    )

                                  ],
                                ),
                              ),
                          SizedBox(height: 15.h,),
                          !isTyping?
                          ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              elevation: 0,
                              minimumSize: Size(double.infinity.w, 55.h),
                            ),
                            child: Text(
                              'Add category',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          )
                          :CustomAppButton(
                              onPressed: (){
                                final category = CategoryModel(
                                    categoryName: _nameController.text,
                                    icon: IconData(
                                      ref.read(iconCodeProvider),
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    categoryType: categoryType,
                                    color: ref.read(colorProvider),
                                );

                                ref.read(categoryProvider.notifier).addCategory(category);

                                Navigator.pop(context);
                              },
                              title: 'Add category'
                          ),
                          SizedBox(height: 10.h,),
                        ],
                      ),
                    ),
                  ),
                );
              }
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
        backgroundColor: Theme.of(context).cardColor,
        showDragHandle: true,
        isScrollControlled: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
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

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    width: double.infinity.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h,),
                          Text('Edit category',style: theme.textTheme.titleLarge,),
                          SizedBox(height: 15.h,),
                          TextField(
                            autofocus: true,
                            controller: _editNameController,
                            decoration: InputDecoration(
                                hintText: 'Enter a category name',
                                hintStyle: theme.textTheme.labelLarge?.copyWith(color: AppColors.hintTextColor)
                            ),
                            onChanged: (_) => checkTyping(ref,category: category),
                          ),
                          SizedBox(height: 15.h,),
                          Text('Choose icon',style: theme.textTheme.titleMedium,),
                          SizedBox(height: 10.h,),
                          Container(
                              height: 80.h,
                              decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...icons.asMap().entries.map((i) {
                                      final index = i.key;
                                      final icon = i.value;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: IconButton(
                                          onPressed: () {
                                            iconNotifier.state = index;
                                            ref.read(iconCodeProvider.notifier).state = icon.codePoint;
                                            checkTyping(ref,category: category);
                                          },
                                          icon: isIconSelected == index
                                              ? Icon(icon, color: theme.colorScheme.primary, size: 30)
                                              : Icon(icon, color: theme.iconTheme.color, size: 30),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 15.h,),
                          Text('Choose category type',style: theme.textTheme.titleMedium,),
                          SizedBox(height: 10.h,),
                          SizedBox(
                            width: double.infinity.w,
                            height: 45.h,
                            child: SegmentedButton(
                              style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith((state){
                                    if(state.contains(WidgetState.selected)){
                                      return selected.contains('expense')? Colors.redAccent : Colors.green;
                                    }
                                    return Colors.transparent;
                                  }),

                                  foregroundColor: WidgetStateProperty.resolveWith((state){
                                    if(state.contains(WidgetState.selected)){
                                      return Colors.white;
                                    }
                                    return theme.colorScheme.onSurface;
                                  }),

                                  side: WidgetStatePropertyAll(BorderSide(color: theme.dividerColor.withOpacity(0.3)))
                              ),
                              segments: [
                                ButtonSegment(
                                    value: 'income',
                                    label: Text('Income')
                                ),
                                ButtonSegment(
                                    value: 'expense',
                                    label: Text('Expense')
                                ),
                              ],

                              selected: selected,
                              onSelectionChanged: (Set<String> newSelection){
                                selectedNotifier.state = newSelection;
                                categoryTypeNotifier.state = newSelection.first=='income'? CategoryType.income : CategoryType.expense;
                                checkTyping(ref,category: category);
                              },
                            ),
                          ),
                          SizedBox(height: 15.h,),
                          Text('Choose background color',style: theme.textTheme.titleMedium,),
                          SizedBox(height: 10.h,),
                          Container(
                            height: 240.h,
                            decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 15.h,),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ...colors.asMap().entries.map((i){
                                        final index = i.key;
                                        final value = i.value;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                              radius: 20,
                                              backgroundColor: value,
                                              child: isColorPickedFromPicker?SizedBox.shrink():isColorPickedFromDefault==index?Icon(Icons.check,color: Colors.white,):SizedBox.shrink(),
                                            ),
                                          ),
                                        );
                                      })
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h,),
                                Padding(
                                  padding: const EdgeInsets.only(left: 100),
                                  child: Text('Or, Pick a custom color',style: theme.textTheme.titleMedium,),
                                ),
                                SizedBox(height: 10.h,),
                                Padding(
                                  padding: const EdgeInsets.only(left: 150),
                                  child: IconButton(
                                      onPressed: (){
                                        pickColorDialogue(category: category);
                                      },
                                      icon: Icon(Icons.colorize,color: theme.iconTheme.color,size: 60,)
                                  ),
                                ),
                                Visibility(
                                  visible: ref.watch(colorPickerCheck),
                                  replacement: SizedBox.shrink(),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 22),
                                    child: Row(
                                      children: [
                                        Text('Selected color code : ',style: theme.textTheme.titleMedium),
                                        SizedBox(width: 5.w,),
                                        Text('#${rgb}',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),),
                                        IconButton(
                                            onPressed: (){
                                              final code = ref.watch(colorCodeProvider);
                                              Clipboard.setData(ClipboardData(text: code));

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Copied to clipboard')),
                                              );
                                            },
                                            icon: Icon(Icons.copy,color: theme.iconTheme.color,)
                                        )
                                      ],

                                    ),
                                  ),
                                )

                              ],
                            ),
                          ),
                          SizedBox(height: 15.h,),
                          !isTyping?
                          ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              elevation: 0,
                              minimumSize: Size(double.infinity.w, 55.h),
                            ),
                            child: Text(
                              'Edit category',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          )
                              :CustomAppButton(
                              onPressed: (){
                                final category = CategoryModel(
                                  categoryId: id,
                                  categoryName: _editNameController.text,
                                  icon: IconData(
                                    ref.read(iconCodeProvider),
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  categoryType: categoryType,
                                  color: ref.read(colorProvider),
                                );

                                ref.read(categoryProvider.notifier).updateCategory(category);

                                Navigator.pop(context);
                              },
                              title: 'Edit category'
                          ),
                          SizedBox(height: 10.h,),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        }
    ).then((_){
      ref.read(editCategoryProvider.notifier).state = false;
      ref.read(checkCategoryTypingProvider.notifier).state = false;
    });
  }

  void categoryDetailsSheet(CategoryModel category) {
    showModalBottomSheet(
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final allRecords = ref.read(expenseProvider).expenses.where((i) => i.category == category.categoryName).toList();

        var theme = Theme.of(context);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.r),
              topRight: Radius.circular(28.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  children: [
                    Text(
                      'Category Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14.sp,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'All time',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: category.color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            colors: [
                              category.color.withOpacity(0.9),
                              category.color.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          category.icon,
                          color: Colors.white,
                          size: 28.sp,
                        ),
                      ),

                      SizedBox(width: 16.w),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.categoryName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '${category.categoryType.name[0].toUpperCase()}${category.categoryType.name.substring(1)} Category',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: category.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: theme.colorScheme.primary,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              allRecords.isEmpty ? 'No records yet' : allRecords.length == 1 ? '1 Record'
                                  : '${allRecords.length} Records',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              allRecords.isEmpty ? 'Start adding transactions' : 'Total transactions in this category',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (allRecords.length > 1)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              allRecords.sort((a, b) => b.date.compareTo(a.date));
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              child: Icon(
                                Icons.sort_rounded,
                                color: theme.colorScheme.primary,
                                size: 24.sp,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              if (allRecords.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Text(
                    'Recent Transactions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ),

              Expanded(
                child: allRecords.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inbox_rounded,
                          size: 48.sp,
                          color: category.color.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No transactions yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Transactions will appear here',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: allRecords.length,
                  itemBuilder: (context, index) {
                    final data = allRecords[index];
                    final accountName = ref.read(cardsProvider).cards.firstWhere(
                          (i) => i.id == data.accountId,
                      orElse: () => CardModel(
                        cardName: 'Unknown',
                        amount: 0.0,
                        icon: Icons.error_outline,
                      ),
                    );

                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: category.color.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        leading: Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 22.sp,
                          ),
                        ),
                        title: Text(
                          data.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              accountName.icon,
                              size: 14.sp,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              accountName.cardName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: category.categoryType == CategoryType.expense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${category.categoryType == CategoryType.expense ? '-' : '+'}${data.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: category.categoryType == CategoryType.expense
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
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
  }

  void bulkDeleteAlert(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text('Delete selected records?',style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),),
            content: Text('This can not be undone.',style: Theme.of(context).textTheme.titleSmall,),
            actions: [
              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text('Cancel',style: Theme.of(context).textTheme.titleMedium,)
              ),
              TextButton(
                  onPressed: (){
                    ref.read(categoryProvider.notifier).bulkDeleteCategories(ref.read(selectedCategoryIdsProvider).toList());
                    ref.read(selectedCategoryIdsProvider).clear();
                    ref.read(isCategoryIdsSelectedForBulkDeleteProvider.notifier).state = false;
                    Navigator.pop(context);
                  },
                  child: Text('Delete',style: Theme.of(context).textTheme.titleMedium,)
              ),
            ],
          );
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    final incomeCategoryState = ref.watch(categoryProvider).allIncomeCategories;

    final expenseCategoryState = ref.watch(categoryProvider).allExpenseCategories;

    final categoryNotifier = ref.read(categoryProvider.notifier);

    final cardState = ref.watch(cardsProvider);

    final totalAccountBalance = cardState.cards.fold(0.0, (sum,value)=>sum+value.amount);

    final averageUsage = cardState.cards.isEmpty?0.0:cardState.cards.fold(0.0, (sum,avg)=>(sum+avg.progress)/cardState.cards.length);

    final isSelectedForBulkDelete = ref.watch(isCategoryIdsSelectedForBulkDeleteProvider);

    final isSelectedForBulkDeleteNotifier = ref.read(isCategoryIdsSelectedForBulkDeleteProvider.notifier);

    final selectedIdsState = ref.watch(selectedCategoryIdsProvider);

    final selectedIdsNotifier = ref.read(selectedCategoryIdsProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Column(
        children: [
          AccountDashboard(
              avgUsage: averageUsage,
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
              child: NotificationListener(
                onNotification: _handleFabButton,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
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
                                                onSelected: (value) {
                                                  if (value == "edit") {
                                                    editCategory(data);
                                                  } else if (value == "delete") {
                                                    categoryNotifier.deleteCategory(data.categoryId!);
                                                  }
                                                },
                                                itemBuilder: (context) => [
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
                                          onSelected: (value) {
                                            if (value == "edit") {
                                              editCategory(data);
                                            } else if (value == "delete") {
                                              categoryNotifier.deleteCategory(data.categoryId!);
                                            }
                                          },
                                          itemBuilder: (context) => [
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
