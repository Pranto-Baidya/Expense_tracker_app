import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BuildPage extends ConsumerStatefulWidget {
  final String title;
  final String? secondaryTitle;
  final String imageSource;
  final String subtitle;
  final bool? isLottie;
  final bool? isCurrencyPage;
  final PageController pageController;
  final int pageCount;

  const BuildPage({
    required this.title,
    this.secondaryTitle,
    this.isLottie,
    this.isCurrencyPage,
    required this.imageSource,
    required this.subtitle,
    required this.pageController,
    required this.pageCount,
    super.key
  });

  @override
  ConsumerState<BuildPage> createState() => _BuildPageState();
}

class _BuildPageState extends ConsumerState<BuildPage> with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyData = ref.watch(newCurrencyProvider);
    final currencyNotifier = ref.read(newCurrencyProvider.notifier);

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

    List<String> currencyNames = [
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

    Map<String,String> merge = {};

    for(var i=0; i<currencies.length; i++){
      merge[currencies[i]] = currencyNames[i];
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 5.h,),
          FadeTransition(
            opacity: _fadeAnim,
            child: RichText(
              text: TextSpan(
                  text: widget.title,
                  style: theme.textTheme.titleLarge,
                  children: [
                    TextSpan(
                        text: widget.secondaryTitle,
                        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)
                    )
                  ]
              ),
            ),
          ),
          SizedBox(height: 40.h,),
          widget.isLottie == true?
          Padding(
            padding: EdgeInsets.only(right: 178.w),
            child: Lottie.asset(
              widget.imageSource,
              fit: BoxFit.cover,
              width: 180.w,
              height: 285.h,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 180.w,
                  height: 180.h,
                  color: Colors.grey.withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                  ),
                );
              },
            ),
          ):FadeTransition(
            opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                  child: Image.asset(widget.imageSource,fit: BoxFit.cover,width: 280.w,height: 280.h,)
              )
          ),
          widget.isCurrencyPage == true ? FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                children: [
                  SizedBox(height: 40.h,),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: DropdownButtonFormField2(
                        isExpanded: true,
                        value: currencyData.currency,
                        items: [
                          ...merge.entries.map((val){

                            final currency = val.key;
                            final cName = val.value;

                            return DropdownMenuItem(
                                value: currency,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(currency,style: theme.textTheme.titleMedium,),
                                    SizedBox(width: 10.w,),
                                    Text(cName,style: theme.textTheme.titleMedium,overflow: TextOverflow.ellipsis,)
                                  ],
                                )
                            );
                          })
                        ],
                        onChanged: (val){
                          currencyNotifier.saveCurrency(val.toString());
                        },
                        decoration: InputDecoration(
                          labelText: 'Choose currency',
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
                        iconStyleData: IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                          ),
                          iconSize: 24,
                        ),
                        buttonStyleData: ButtonStyleData(
                          height: 56.h,
                          padding: EdgeInsets.zero,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.cardColor,
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      )
                  ),
                ],
              ),
            ),
          ):SizedBox.shrink(),
          SizedBox(height: 40.h,),
          FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(widget.subtitle,style: theme.textTheme.titleMedium,textAlign: TextAlign.center,),
            ),
          ),

          widget.pageCount==5?SizedBox(height: 20.h,):SizedBox(height: 40.h,),
          FadeTransition(
            opacity: _fadeAnim,
            child: SmoothPageIndicator(
              controller: widget.pageController,
              count: widget.pageCount,
              effect: ExpandingDotsEffect(
                  activeDotColor: theme.colorScheme.primary,
                  dotColor: theme.colorScheme.onSurface,
                  dotHeight: 10.h,
                  dotWidth: 10.h
              ),
            ),
          ),
        ],
      ),
    );
  }
}