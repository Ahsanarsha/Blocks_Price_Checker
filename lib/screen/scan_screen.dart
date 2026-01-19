// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:blocks_guide/helpers/connection_helper.dart';
import 'package:blocks_guide/helpers/connection_provider.dart';
import 'package:blocks_guide/helpers/kiosk_mode_manager.dart';
import 'package:blocks_guide/core/theme/app_theme.dart';
import 'package:blocks_guide/widgets/widgets.dart';
import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class ProductModel {
  final String keycode;
  final String sku;
  final String name;
  double retailPrice;
  double? specialPrice;
  String? mixAndMatch;

  ProductModel({
    required this.keycode,
    required this.sku,
    required this.name,
    required this.retailPrice,
    this.specialPrice,
    this.mixAndMatch,
  });

  @override
  String toString() =>
      'ProductModel{keycode: $keycode, sku: $sku, name: $name, retailPrice: $retailPrice, specialPrice: $specialPrice, mixAndMatch: $mixAndMatch}';
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final MethodChannel platform =
      const MethodChannel('com.eratech.blocks_price_check/kiosk_mode');
  List<ProductModel> productList = [];
  bool isLoading = false;
  final FocusNode _focusNode = FocusNode();
  TextEditingController controller = TextEditingController();
  final _sqlConnection = ConnectToSqlServerDirectly();
  Uint8List? imageBytes;
  bool _showKeyboard = false;
  String _scanBuffer = '';

  // Current app build number - update this when releasing new versions
  static const int _currentBuildNumber = 9;
  static const String _currentVersionNumber = "1.1.7";

  String? _latestApkApiKeycode;
  String domainUrl = "https://apis.blocks360.net";

  // Gradient colors for animated background
  int _colorIndex = 0;
  Color _bottomColor = AppColors.gradientSets[0][0];
  Color _topColor = AppColors.gradientSets[0][1];

  // Animation controllers
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late Timer _gradientTimer;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  Timer? _clearProductTimer;
  late Timer _connectionCheckTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kiosk mode is now controlled manually via buttons in the settings popup
  }

  bool isWithinDateRange(
      DateTime startDate, DateTime endDate, DateTime currentDate) {
    return startDate.isBefore(currentDate) && endDate.isAfter(currentDate);
  }

  bool isWithinTimeRange(
      String startTime, String endTime, DateTime currentTime) {
    final format = DateFormat.Hms();
    final start = format.parse(startTime);
    final end = format.parse(endTime);
    return currentTime.isAfter(start) && currentTime.isBefore(end);
  }

  Future<String> getMixAndMatchData(String productId) async {
    log("product id receiving: $productId");
    String mixMatchText = '';
    final today = DateTime.now();

    List<String> weekdays = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    String currentDayName = weekdays[today.weekday % 7];
    String weekdayCheck = "${currentDayName}_Check";

    log('Current Day: $weekdayCheck');
    var data = [];
    try {
      log('Before query execution');

      final response = await _sqlConnection.getRowsOfQueryResult("""
        SELECT MAM.Name
        FROM MixMatch MAM
        INNER JOIN MixMatchProduct MAMP ON MAM.keycode = MAMP.MixMatchkeycode
        WHERE MAMP.Productkeycode = '$productId'
          AND MAM.IsActiveRecord = '1'
          AND ((MAM.IsLimitedDates = '1' AND GETDATE() BETWEEN MAM.StartDate AND MAM.EndDate) OR MAM.IsLimitedDates = '0')
          AND ((MAM.IsTimeRestricted = '1' AND GETDATE() BETWEEN MAM.StartTime AND MAM.EndTime) OR MAM.IsTimeRestricted = '0')
      """) as List? ?? [];

      log('getMixAndMatchData response >>> $response');
      if (response.isNotEmpty) {
        for (var row in response) {
          bool isDayValid = row[weekdayCheck] == true || row[weekdayCheck] == 1;
          bool isDateRes = row['Is_Limited_Date'] == true ? true : false;

          log('Weekday check for $currentDayName: $isDayValid');

          if (isDateRes && !isDayValid) {
            log('Mix and Match not valid for today\'s weekday');
            return '';
          }
          setState(() {
            mixMatchText = row['Name'];
          });

          data.clear();
          data.add(row);
          log('Mix and match data: $data >>> Name: ${row['Name']}');
        }
      } else {
        setState(() {
          mixMatchText = '';
        });
      }
    } catch (e) {
      print('Error fetching Mix and Match data: $e');
    }

    return mixMatchText;
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Bounce animation for scanner hint
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _bounceController.repeat(reverse: true);

    // Gradient color transition timer
    _gradientTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _colorIndex = (_colorIndex + 1) % AppColors.gradientSets.length;
        _bottomColor = AppColors.gradientSets[_colorIndex][0];
        _topColor = AppColors.gradientSets[_colorIndex][1];
      });
    });

    // Scale animation for promotions
    _scaleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.85).animate(_scaleController);

    // Color animation for promotions
    _colorController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: AppColors.success,
      end: AppColors.error,
    ).animate(_colorController);

    // Check database connection on app start
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    ConnectionHelper().checkInitialConnection(connectionProvider);

    // Check database connection periodically
    _connectionCheckTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) async {
      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);
      ConnectionProvider().loadConnectionStatus();
      await ConnectionHelper().checkInitialConnection(connectionProvider);
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    controller.dispose();
    _bounceController.dispose();
    _scaleController.dispose();
    _colorController.dispose();
    _gradientTimer.cancel();
    _connectionCheckTimer.cancel();
    _clearProductTimer?.cancel();
    super.dispose();
  }

  void _startClearProductTimer() {
    _clearProductTimer?.cancel();

    _clearProductTimer = Timer(const Duration(seconds: 15), () {
      setState(() {
        productList.clear();
        imageBytes = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCustomSnackBar('Product data cleared');
        }
      });
    });
  }

  Future<bool> _checkAppVersion() async {
    try {
      final response = await http
          .get(
            Uri.parse('$domainUrl/api/v1/MobileBuildInfo/Application?app=1'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final int serverBuildNumber = data['data']['mobileBuildNumber'] ?? 0;
          _latestApkApiKeycode = data['data']['keycode'];

          log('Server build number: $serverBuildNumber, Current build number: $_currentBuildNumber');

          if (serverBuildNumber > _currentBuildNumber) {
            _showUpdateRequiredModal();
            return false;
          }
        }
      }
      return true;
    } catch (e) {
      log('Error checking app version: $e');
      return true;
    }
  }

  Future<void> _showErrorDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error Icon
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 24.sp,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 7.sp,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBuildInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.35,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Icon
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.accentTeal],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 24.sp,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 12.h),

                // Title
                Text(
                  'App Information',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),

                // Build Number
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Build Number',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$_currentBuildNumber',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                // Version Number
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Version Number',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _currentVersionNumber,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadAndInstallApk() async {
    if (_latestApkApiKeycode == null) {
      _showErrorDialog(
          'Update Error', 'Update path not available. Please try again later.');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      color: AppColors.accentBlue,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    'Downloading update...',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final downloadUrl =
          '$domainUrl/api/v1/MobileBuildInfo/Download?keycode=$_latestApkApiKeycode';
      log('Downloading APK from: $downloadUrl');

      final response = await http.get(Uri.parse(downloadUrl)).timeout(
            const Duration(minutes: 25),
          );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final apkFile = File('${tempDir.path}/app_update.apk');
        await apkFile.writeAsBytes(response.bodyBytes);

        log('APK saved to: ${apkFile.path}');

        if (mounted) Navigator.pop(context);

        log('Disabling kiosk mode before APK installation...');
        await KioskModeManager.stopKioskMode();

        await Future.delayed(const Duration(milliseconds: 600));

        final result = await OpenFilex.open(apkFile.path);
        log('Open file result: ${result.type} - ${result.message}');

        if (result.type != ResultType.done) {
          _showErrorDialog('Installation Error',
              'Failed to open installer: ${result.message}');
        }
      } else {
        if (mounted) Navigator.pop(context);
        _showErrorDialog('Download Failed',
            'Failed to download update. Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error downloading/installing APK: $e');
      if (mounted) Navigator.pop(context);
      _showErrorDialog(
          'Update Error', 'An error occurred while updating the app: $e');
    }
  }

  void _showUpdateRequiredModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Container(
            margin: EdgeInsets.all(12.r),
            padding: EdgeInsets.all(16.r),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning.withValues(alpha: 0.2),
                          AppColors.warning.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 20.sp,
                      color: AppColors.warning,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Update Required',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'A new version is available. Please update to continue using the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 6.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _downloadAndInstallApk();
                      },
                      child: Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 6.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchProductWithVersionCheck(String text) async {
    // final isVersionValid = await 
    _checkAppVersion();
    // if (isVersionValid) {
      getProductsTableData(text);
    // }
  }

  Future<void> getProductsTableData(String text) async {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    if (!connectionProvider.isConnected) {
      _showCustomSnackBar('Please connect to the database first');
      return;
    }

    setState(() {
      isLoading = true;
      controller.text = text;
    });
    productList.clear();
    log('Product list empty: ${productList.isEmpty}');
    log('Scanned text: $text');

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      _showCustomSnackBar('No internet connection. Please check your network.');
      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    bool connect = false;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getString('serverIp') != null &&
          prefs.getString('database') != null &&
          prefs.getString('userName') != null &&
          prefs.getString('password') != null) {
        final tables = await _sqlConnection.getRowsOfQueryResult(
                'SELECT * FROM INFORMATION_SCHEMA.TABLES') as List? ??
            [];

        log('Tables>>> $tables');

        if (tables.isNotEmpty) {
          List<Map<String, dynamic>> tablesList =
              tables.cast<Map<String, dynamic>>();
          log('Tables List>>> $tablesList');
          connect = tablesList.isNotEmpty;
        }

        print("Connected to $connect");
      }
    } catch (e) {
      print('Failed to connect to the database: $e');

      if (e.toString().contains('Host unreachable')) {
        _showCustomSnackBar('Please connect to the same network as the server');
      } else {
        _showCustomSnackBar('Network Error: SQL server is unreachable');
      }

      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    if (!connect) {
      _showCustomSnackBar('Unable to connect to the server');
      setState(() {
        isLoading = false;
        controller.text = '';
      });
      return;
    }

    try {
      final today = DateTime.now();
      log('Today Date: $today');

      final productResponse = await _sqlConnection.getRowsOfQueryResult("""
        SELECT keycode, ProductName, RetailPrice, ProductNature, TaxNonTax, EBTEligible, WeightItem, LoyaltyPoint
        FROM Products
        WHERE keycode IN (SELECT Productkeycode FROM ProductSKUs WHERE ProductSKU = '$text');
        """);
      log('Query text: $text');
      log('Product response: $productResponse');

      if (productResponse is! List) {
        _showCustomSnackBar('Failed to fetch product data');
      } else {
        List<Map<String, dynamic>> tempResult =
            productResponse.cast<Map<String, dynamic>>();
        log('Temp Result>>>:  $tempResult');

        for (var element in tempResult) {
          log('Before query execution');

          String mixMatch =
              await getMixAndMatchData(element['keycode'].toString());
          log('MixMatch: $mixMatch');
          _addProduct(element, mixMatch: mixMatch);
          log('product id ${element['Id'].toString()}');
        }
      }

      final specialPriceResponse = await _sqlConnection.getRowsOfQueryResult("""
SELECT keycode, SpecialPrice FROM Products WHERE keycode = (select Productkeycode from ProductSKUs where ProductSKU = '$text')
AND CONVERT(DATE, GETDATE()) BETWEEN CONVERT(DATE, StartDate) AND CONVERT(DATE, EndDate) AND OnSpecial = 1
""") as List? ?? [];

      log('special Price Response:    $specialPriceResponse');
      if (specialPriceResponse.isNotEmpty) {
        for (var product in productList) {
          print("product $product");
          List<Map<String, dynamic>> tempResult =
              specialPriceResponse.cast<Map<String, dynamic>>();
          for (var e in tempResult) {
            print('Temp Result: $tempResult');
            if (product.keycode == e['keycode'].toString()) {
              product.specialPrice =
                  double.tryParse(e["SpecialPrice"].toString()) ?? 0.0;
              print('Special Price: ${product.specialPrice}');
            }
          }
        }
      }

      if (productList.isEmpty) {
        _showCustomSnackBar('No product found');
      } else {
        List<Map<String, dynamic>> tempResult =
            productResponse.cast<Map<String, dynamic>>();
        log("product keycode : ${tempResult.first['keycode']}");
        final imageResponse = await _sqlConnection.getRowsOfQueryResult(
              "select CAST(N'' AS XML).value('xs:base64Binary(xs:hexBinary(sql:column(\"ImageHex\")))', 'VARCHAR(MAX)') AS ImageData from (select CONVERT(VARCHAR(MAX), ImageData, 2) AS ImageHex from Products where keycode = ${tempResult.first['keycode']}) AS T",
            ) as List? ??
            [];
        log('Image Response:    $imageResponse');
        if (imageResponse.isNotEmpty) {
          final base64String = imageResponse.first["ImageData"] ?? '';
          if (base64String.isNotEmpty) {
            try {
              imageBytes = base64Decode(base64String);
              log('Image bytes length: ${imageBytes?.length}');
            } catch (e) {
              log('Failed to decode image: $e');
              imageBytes = null;
            }
          } else {
            imageBytes = null;
          }
        } else {
          imageBytes = null;
        }
      }
    } catch (error) {
      print('Error occurred while querying data: $error');
      _showCustomSnackBar('An error occurred while fetching data');
    }

    setState(() {
      isLoading = false;
      controller.text = '';
      _startClearProductTimer();
    });
  }

  void _addProduct(Map<String, dynamic> element, {String mixMatch = ''}) {
    final keycode = element['keycode']?.toString() ?? '';
    final sku = element['ProductSKU']?.toString() ?? '';
    final name = element['ProductName'] ?? 'Unknown Product';
    final retailPrice =
        double.tryParse(element['RetailPrice']?.toString() ?? '0.0') ?? 0.0;
    final specialPrice =
        double.tryParse(element['SpecialPrice']?.toString() ?? '0.0') ?? 0.0;

    log('Adding product to list (current empty: ${productList.isEmpty})');

    if (keycode.isNotEmpty) {
      productList.add(
        ProductModel(
          keycode: keycode,
          sku: sku,
          name: name,
          retailPrice: retailPrice,
          specialPrice: specialPrice,
          mixAndMatch: mixMatch,
        ),
      );
    }
  }

  void _showCustomSnackBar(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.08,
        left: MediaQuery.of(context).size.width * 0.2,
        width: MediaQuery.of(context).size.width * 0.6,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryMedium],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.white,
                  size: 16.sp,
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!_showKeyboard && event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        if (_scanBuffer.isNotEmpty) {
          log('Scanner input: $_scanBuffer');
          controller.text = _scanBuffer;
          _fetchProductWithVersionCheck(_scanBuffer);
          _scanBuffer = '';
        }
      } else {
        final keyLabel = event.character;
        if (keyLabel != null && RegExp(r'[0-9]').hasMatch(keyLabel)) {
          _scanBuffer += keyLabel;
          controller.text = _scanBuffer;
        }
      }
    }
  }

  void _handleFieldSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      log('Searching for: $value');
      _fetchProductWithVersionCheck(value);
    }
    setState(() {
      _showKeyboard = false;
    });
    controller.clear();
    _scanBuffer = '';
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Stack(
          children: [
            // Animated gradient background
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_topColor, _bottomColor],
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  Consumer<ConnectionProvider>(
                    builder: (context, connectionProvider, child) {
                      return CustomAppBar(
                        title: 'Price Checker',
                        topColor: _topColor,
                        bottomColor: _bottomColor,
                        isConnected: connectionProvider.isConnected,
                        onSettingsPressed: () {
                          FocusScope.of(context).unfocus();
                          KioskModeManager().showPasswordDialog(context);
                        },
                        onDoubleTap: _showBuildInfoDialog,
                      );
                    },
                  ),

                  // Body content
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Column(
                        children: [
                          // Scanner input field
                          ScannerInputField(
                            controller: controller,
                            focusNode: _focusNode,
                            showKeyboard: _showKeyboard,
                            onSubmitted: _handleFieldSubmitted,
                            onKeyEvent: _handleKeyEvent,
                            onTap: () {
                              setState(() {
                                _showKeyboard = true;
                              });
                            },
                          ),
                          SizedBox(height: 10.h),

                          // Product display area
                          Expanded(
                            child: _buildProductArea(),
                          ),
                          SizedBox(height: 6.h),

                          // Scanner hint
                          ScannerHintWidget(
                            bounceAnimation: _bounceAnimation,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductArea() {
    if (isLoading) {
      return const LoadingWidget(
        message: 'Fetching product information...',
      );
    }

    if (productList.isEmpty) {
      return Consumer<ConnectionProvider>(
        builder: (context, connectionProvider, child) {
          return EmptyStateWidget(
            isConnected: connectionProvider.isConnected,
          );
        },
      );
    }

    // Product display
    final product = productList.first;
    return ProductDisplayCard(
      productName: product.name,
      retailPrice: product.retailPrice,
      specialPrice: product.specialPrice,
      mixAndMatch: product.mixAndMatch,
      imageBytes: imageBytes,
      scaleAnimation: _scaleAnimation,
      colorAnimation: _colorAnimation,
    );
  }
}
