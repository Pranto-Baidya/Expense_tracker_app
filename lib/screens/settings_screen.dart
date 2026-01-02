import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../notification/notification_service.dart';
import '../riverpod/accent_riverpod/accent_riverpod.dart';
import '../riverpod/auth_riverpod/auth_riverpod.dart';
import '../riverpod/currency_riverpod/currency_pref.dart';
import '../riverpod/prefs_riverpod/prefs_riverpod.dart';
import '../riverpod/theme_riverpod/theme_riverpod.dart';
import '../widgets/custom_app_button.dart';
import 'all_screens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _pinController = TextEditingController();

  void chooseTheme() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        var theme = Theme.of(context);

        return Consumer(
          builder: (context, ref, _) {
            final selected = ref.watch(themeModeProvider);
            final selectedNotifier = ref.read(themeModeProvider.notifier);

            return AlertDialog(
              backgroundColor: theme.cardColor,
              title: Row(
                children: [
                  Text(
                    'Choose mode',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...ThemeMode.values.map((mode) {
                    return RadioListTile(
                      value: mode,
                      tileColor: Colors.transparent,
                      fillColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.primary,
                      ),
                      title: mode == ThemeMode.system ? Text('System') : mode == ThemeMode.light ? Text('Light') : Text('Dark'),
                      groupValue: selected,
                      onChanged: (val) {
                        if (val != null) {
                          selectedNotifier.saveTheme(val);
                          Navigator.pop(context);
                        }
                      },
                    );
                  })
                ],
              ),
            );
          },
        );
      },
    );
  }

  void chooseCurrency(){
    showDialog(
        context: context,
        builder: (BuildContext context){

          var theme = Theme.of(context);

          List<String> currencies = [
            // Americas
            "\$",   // USD, CAD, AUD, NZD, SGD, HKD
            "₱",    // PHP
            "₡",    // CRC
            "₲",    // PYG
            "₦",    // NGN
            "₵",    // GHS
            "₠",    // ECU (legacy)
            "₢",    // Cruzeiro (legacy)
            "₧",    // Peseta (legacy)

            // Europe
            "€",    // EUR
            "£",    // GBP
            "₽",    // RUB
            "₴",    // UAH
            "₺",    // TRY
            "₣",    // Franc (CHF legacy symbol)
            "kr",   // SEK, NOK, DKK, ISK
            "zł",   // PLN
            "lei",  // RON, MDL
            "Ft",   // HUF
            "Kč",   // CZK
            "₮",    // MNT (also Asia)

            // South Asia
            "₹",    // INR
            "৳",    // BDT
            "₨",    // PKR, LKR, NPR, MVR
            "؋",    // AFN
            "៛",    // KHR

            // East Asia
            "¥",    // JPY, CNY
            "₩",    // KRW
            "元",    // CNY (Yuan text)
            "円",    // JPY (Yen text)

            // Southeast Asia
            "฿",    // THB
            "₫",    // VND
            "RM",   // MYR
            "Rp",   // IDR
            "₭",    // LAK
            "B\$",   // BND

            // Middle East
            "₪",    // ILS
            "﷼",    // SAR, IRR, QAR, OMR, YER, MAD
            "د.إ",  // AED
            "د.ك",  // KWD
            "د.ب",  // BHD
            "ل.ل",  // LBP

            // Africa
            "R",    // ZAR
            "Br",   // ETB
            "Sh",   // KES, TZS, UGX
            "CFA",  // XOF, XAF

            // Central Asia
            "₸",    // KZT
            "₼",    // AZN
            "₾",    // GEL
            "som",  // KGS

            // Special / Others
            "₿",    // Bitcoin
            "Ξ",    // Ethereum
            "Ł",    // PLN (alt)
            "₯",    // Drachma (legacy)
          ];

          List<String> currencyName = [
            // Americas
            "Dollar",
            "Philippine Peso",
            "Costa Rican Colón",
            "Paraguayan Guaraní",
            "Nigerian Naira",
            "Ghanaian Cedi",
            "European Currency Unit (Legacy)",
            "Brazilian Cruzeiro (Legacy)",
            "Spanish Peseta (Legacy)",

            // Europe
            "Euro",
            "British Pound Sterling",
            "Russian Ruble",
            "Ukrainian Hryvnia",
            "Turkish Lira",
            "Franc (Swiss / Legacy)",
            "Scandinavian Krona",
            "Polish Złoty",
            "Leu (Romanian / Moldovan)",
            "Hungarian Forint",
            "Czech Koruna",
            "Mongolian Tögrög",

            // South Asia
            "Indian Rupee",
            "Bangladeshi Taka",
            "Rupee (Pakistani/Sri Lankan/Nepalese/Maldivian)",
            "Afghan Afghani",
            "Cambodian Riel",

            // East Asia
            "Yen / Yuan",
            "South Korean Won",
            "Chinese Yuan (Text)",
            "Japanese Yen (Text)",

            // Southeast Asia
            "Thai Baht",
            "Vietnamese Dong",
            "Malaysian Ringgit",
            "Indonesian Rupiah",
            "Lao Kip",
            "Brunei Dollar",

            // Middle East
            "Israeli New Shekel",
            "Riyal (Saudi/Iranian/Qatari/Omani/Yemeni/Moroccan)",
            "UAE Dirham",
            "Kuwaiti Dinar",
            "Bahraini Dinar",
            "Lebanese Pound",

            // Africa
            "South African Rand",
            "Ethiopian Birr",
            "Shilling (Kenyan/Tanzanian/Ugandan)",
            "CFA Franc",

            // Central Asia
            "Kazakhstani Tenge",
            "Azerbaijani Manat",
            "Georgian Lari",
            "Kyrgyzstani Som",

            // Special / Others
            "Bitcoin",
            "Ethereum",
            "Polish Złoty (Alt)",
            "Greek Drachma (Legacy)",
          ];

          Map<String,String> currMap = {};

          for(var i=0; i<currencies.length; i++){
            currMap[currencies[i]] = currencyName[i];
          }

          return Consumer(
              builder: (context,ref,_){

                final selected = ref.watch(newCurrencyProvider).currency;
                final selectedNotifier = ref.read(newCurrencyProvider.notifier);

                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title: Row(
                    children: [
                      Text('Choose currency',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
                      Spacer(),
                      IconButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close,color: theme.colorScheme.primary,size: 30,)
                      )
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...currMap.entries.map((curr){
                        return RadioListTile(
                          tileColor: Colors.transparent,
                          value: curr.key,
                          fillColor: WidgetStatePropertyAll(theme.colorScheme.primary),
                          title: Row(
                            children: [
                              Text(curr.key),
                              SizedBox(width: 5,),
                              Text(curr.value)
                            ],
                          ),
                          groupValue: selected,
                          onChanged: (val){
                            if(val!=null){
                              selectedNotifier.saveCurrency(val);
                              Navigator.pop(context);
                            }
                          },

                        );
                      })
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  void setPin(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
              builder: (context,ref,_){
                final obSecureState = ref.watch(obSecureProvider);
                final authNotifier = ref.read(authProvider.notifier);
                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title:  Row(
                    children: [
                      Text('Set 4 digit PIN',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18,color: theme.colorScheme.primary),),
                      Spacer(),
                      IconButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close,color: theme.colorScheme.primary,size: 30,)
                      )
                    ],
                  ),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          autofocus: true,
                          controller: _pinController,
                          obscureText: obSecureState,
                          keyboardType: TextInputType.number,
                          validator: (value){
                            if(value!.isEmpty){
                              return "Please enter 4 digit pin code";
                            }
                            else if(value.length<4 || value.length>4){
                              return "Pin code must be of only 4 digits";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                              hintText: 'Enter digits',
                              suffixIcon: IconButton(
                                  onPressed: (){
                                    ref.read(obSecureProvider.notifier).state = !ref.read(obSecureProvider.notifier).state;
                                  },
                                  icon: obSecureState?Icon(Icons.visibility_off_outlined,color: theme.iconTheme.color,):Icon(Icons.visibility_outlined,color: theme.iconTheme.color,)
                              )
                          ),
                        ),
                        SizedBox(height: 15.h,),
                        CustomAppButton(
                            onPressed: (){
                              if(_formKey.currentState!.validate()){
                                authNotifier.savePass(_pinController.text);
                                Navigator.pop(context);
                              }
                            },
                            title: 'Set pin'
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  void pickAccentColor(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
              builder: (context,ref,_){
                List<Color> accentColors = [
                  Color(0xFF0F52BA),
                  Color(0xFF1476B8),
                  Color(0xFF1D9EAE),
                  Color(0xFF006666),
                  Color(0xFF16A085),
                  Color(0xFF558B2F),
                  Color(0xFFAA8811),
                  Color(0xFFC05A14),
                  Color(0xFFB8143A),
                  Color(0xFF9C116E),
                  Color(0xFF7E57C2),
                  Color(0xFF5B4EC4),
                  Color(0xFF8D6E63),
                  Color(0xFF607D8B),
                ];

                List<String> colorName = [
                  'Deep Blue',
                  'Light Blue',
                  'Cyan',
                  'Teal',
                  'Green',
                  'Deep Green',
                  'Gold',
                  'Orange',
                  'Red',
                  'Magenta',
                  'Purple',
                  'Indigo',
                  'Brown',
                  'Slate Grey',
                ];

                Map<String,Color> data = {};

                for(var i=0; i<colorName.length;i++){
                  data[colorName[i]] = accentColors[i];
                }

                final currentColor = ref.watch(accentColorProvider);
                final currentColorNotifier = ref.read(accentColorProvider.notifier);

                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title: Row(
                    children: [
                      Text('Select theme',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...data.entries.map((color){
                          final name = color.key;
                          final colorValue = color.value;
                          return Row(

                            children: [
                              Checkbox(
                                side: BorderSide.none,
                                fillColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return theme.colorScheme.primary;
                                  }
                                  return theme.colorScheme.onSurface.withOpacity(0.1);
                                },
                                ),
                                value: currentColor.value==colorValue.value,
                                onChanged: (val){
                                  currentColorNotifier.saveAccentColor(colorValue);
                                  Navigator.pop(context);
                                },
                              ),
                              Text(name,style: theme.textTheme.titleMedium,),
                              Spacer(),
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: colorValue,
                              )
                            ],
                          );
                        })
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    bool isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
          title: Text('Preferences',style: theme.textTheme.titleLarge,),
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
      body: ListView(
        children: [
          SizedBox(height: 15.h,),
          ListTile(
            tileColor: Colors.transparent,
            title: Text('Appearance',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
          ),
          ListTile(
              onTap: ()=>pickAccentColor(),
              tileColor: Colors.transparent,
              leading: Icon(Icons.color_lens_outlined,color: theme.iconTheme.color,),
              title: Text('App theme'),
              trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
          ),
          ListTile(
              onTap: chooseTheme,
              tileColor: Colors.transparent,
              leading: isDark?Icon(Icons.wb_sunny_outlined,color: theme.iconTheme.color,):Icon(Icons.dark_mode_outlined,color: theme.iconTheme.color,),
              title: Text('Display mode'),
              trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
          ),
          ListTile(
              onTap: chooseCurrency,
              tileColor: Colors.transparent,
              leading: Icon(Icons.paid_outlined,color: theme.iconTheme.color,),
              title: Text('Currency sign'),
              trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
          ),
          ListTile(
              onTap: chooseCurrency,
              tileColor: Colors.transparent,
              leading: Icon(Icons.dashboard_outlined,color: theme.iconTheme.color,),
              title: Text('Enable collapse mode'),
              trailing: Switch(
                  value: ref.watch(collapseDashboardPrefProvider),
                  onChanged: (val){
                    ref.read(collapseDashboardPrefProvider.notifier).saveCollapsePref(val);
                  }
              )
          ),
          Divider(indent: 10,endIndent: 10,thickness: 1,color: theme.colorScheme.primary,),
          ListTile(
            tileColor: Colors.transparent,
            title: Text('Security',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
          ),
          ListTile(
              tileColor: Colors.transparent,
              leading: Icon(Icons.lock_outline,color: theme.iconTheme.color,),
              title: Text('Pin lock protection'),
              trailing:Switch(
                  value: ref.watch(authProvider).isPinSet,
                  onChanged: (val){
                    if(val==true){
                      setPin();
                    }
                    else{
                      ref.read(authProvider.notifier).deletePin();
                    }
                  }
              )
          ),
          Divider(indent: 10,endIndent: 10,thickness: 1,color: theme.colorScheme.primary,),
          ListTile(
            tileColor: Colors.transparent,
            title: Text('Notifications',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
          ),
          ListTile(
              tileColor: Colors.transparent,
              leading: Icon(Icons.notifications_none,color: theme.iconTheme.color,),
              title: Text('Remind everyday'),
              trailing: Switch(
                  value: ref.watch(prefsProvider),
                  onChanged: (val){
                    if(val==true){
                      ref.read(prefsProvider.notifier).savePref(val);
                      NotificationService.showImmediateNotification();
                      NotificationService.sendNotificationAt();
                    }
                    else{
                      NotificationService.cancelNotification();
                      ref.read(prefsProvider.notifier).savePref(val);
                    }
                  })
          ),
        ],
      ),
    );
  }
}
