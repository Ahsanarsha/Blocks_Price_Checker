// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';

import 'package:blocks_guide/core/theme/app_theme.dart';
import 'package:connect_to_sql_server_directly/connect_to_sql_server_directly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connection_provider.dart';

class KioskModeManager {
  static Timer? _popupTimer;
  static bool testSuccess = false;

  static const MethodChannel platform =
      MethodChannel('com.eratech.blocks_price_check/kiosk_mode');

  static Future<void> startKioskMode() async {
    try {
      var result = await platform.invokeMethod('startKioskMode');
      log("Kiosk Mode started: $result");
    } on PlatformException catch (e) {
      log("Failed to start Kiosk Mode: '${e.message}'.");
    }
  }

  static Future<void> stopKioskMode() async {
    try {
      var result = await platform.invokeMethod('stopKioskMode');
      log("Kiosk Mode stopped: $result");
    } on PlatformException catch (e) {
      log("Failed to stop Kiosk Mode: '${e.message}'.");
    }
  }

  Future<void> showPasswordDialog(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    FocusNode passwordFocusNode = FocusNode();
    bool isPasswordVisible = false;

    startPopupTimeout(context, duration: const Duration(seconds: 10));

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.35,
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header icon
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accentBlue.withValues(alpha: 0.2),
                                  AppColors.accentTeal.withValues(alpha: 0.2),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 20.sp,
                              color: AppColors.accentBlue,
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Title
                          Text(
                            'Enter Password',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Enter your password to access settings',
                            style: TextStyle(
                              fontSize: 7.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Password field with visibility toggle
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: passwordController,
                              focusNode: passwordFocusNode,
                              obscureText: !isPasswordVisible,
                              autofocus: true,
                              onChanged: (value) {
                                resetPopupTimeout(context,
                                    duration: const Duration(seconds: 10));
                              },
                              onSubmitted: (value) async {
                                if (passwordController.text == '1234') {
                                  Navigator.of(context).pop();
                                  showDatabasePopup(context);
                                } else {
                                  passwordController.clear();
                                  passwordFocusNode.requestFocus();
                                  _showModernSnackBar(
                                      context, 'Incorrect password',
                                      isError: true);
                                }
                              },
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  fontSize: 8.sp,
                                  color: AppColors.textSecondary,
                                ),
                                prefixIcon: Icon(
                                  Icons.key_rounded,
                                  size: 14.sp,
                                  color: AppColors.accentBlue,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isPasswordVisible = !isPasswordVisible;
                                    });
                                  },
                                  child: Icon(
                                    isPasswordVisible
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    size: 14.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 10.h),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildOutlinedButton(
                                  'Cancel',
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildGradientButton(
                                  'Unlock',
                                  onPressed: () async {
                                    if (passwordController.text == '1234') {
                                      Navigator.of(context).pop();
                                      showDatabasePopup(context);
                                    } else {
                                      passwordController.clear();
                                      passwordFocusNode.requestFocus();
                                      _showModernSnackBar(
                                          context, 'Incorrect password',
                                          isError: true);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    passwordFocusNode.requestFocus();
  }

  Future<void> showDatabasePopup(BuildContext context) async {
    final sqlConnection = ConnectToSqlServerDirectly();
    bool connect = false;

    TextEditingController serverController = TextEditingController();
    TextEditingController databaseController = TextEditingController();
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    // For validation errors
    Map<String, bool> fieldErrors = {
      'server': false,
      'database': false,
      'username': false,
      'password': false,
    };

    // For password visibility
    bool isPasswordVisible = false;

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      serverController.text = prefs.getString('serverIp') ?? '';
      databaseController.text = prefs.getString('database') ?? '';
      usernameController.text = prefs.getString('userName') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
    } catch (e) {
      log('Error loading SharedPreferences: $e');
    }

    // Validate all fields
    bool validateFields(Function setState) {
      bool isValid = true;

      setState(() {
        fieldErrors['server'] = serverController.text.trim().isEmpty;
        fieldErrors['database'] = databaseController.text.trim().isEmpty;
        fieldErrors['username'] = usernameController.text.trim().isEmpty;
        fieldErrors['password'] = passwordController.text.trim().isEmpty;
      });

      if (fieldErrors.values.any((hasError) => hasError)) {
        isValid = false;
      }

      return isValid;
    }

    // Show connection result dialog
    Future<void> showConnectionResultDialog(BuildContext context, bool isSuccess, {String? errorMessage}) async {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.35,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                    // Icon
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: (isSuccess ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        size: 24.sp,
                        color: isSuccess ? AppColors.success : AppColors.error,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Title
                    Text(
                      isSuccess ? 'Connection Successful' : 'Connection Failed',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? AppColors.success : AppColors.error,
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Message
                    Text(
                      isSuccess
                          ? 'Successfully connected to the SQL Server database.'
                          : errorMessage ?? 'Failed to connect to the server. Please check your credentials and try again.',
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
                      child: _buildGradientButton(
                        'OK',
                        color: isSuccess ? AppColors.success : AppColors.error,
                        onPressed: () => Navigator.of(context).pop(),
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

    Future<bool> testConnection(BuildContext context, Function setState) async {
      // Validate fields first
      if (!validateFields(setState)) {
        return false;
      }

      bool isConnected = false;
      String? errorMsg;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: AppColors.accentBlue,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'Testing connection...',
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

      try {
        log('Attempting connection with:');
        log('Server: ${serverController.text}');
        log('Database: ${databaseController.text}');
        log('Username: ${usernameController.text}');

        connect = await sqlConnection.initializeConnection(
          serverController.text.trim(),
          databaseController.text.trim(),
          usernameController.text.trim(),
          passwordController.text.trim(),
        );
        log('Initial connection result: $connect');
      } catch (e) {
        log('Failed to connect to the database: $e');
        errorMsg = e.toString();
        connect = false;
      }

      if (connect) {
        try {
          var tablesResponse = await sqlConnection.getRowsOfQueryResult(
              "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'");
          log('Available tables: $tablesResponse');

          var response = await sqlConnection
              .getRowsOfQueryResult("SELECT TOP 1 * FROM Products");
          log('Product query response: $response');

          isConnected =
              response != null && response is List && response.isNotEmpty;
        } catch (e) {
          log('Error querying database: $e');
          errorMsg = 'Connected but failed to query Products table: $e';
          isConnected = false;
        }
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        setState(() {});

        // Show result dialog
        await showConnectionResultDialog(
          context,
          isConnected,
          errorMessage: errorMsg,
        );
      }

      return isConnected;
    }

    Future<bool> showCancelWarning(BuildContext context) async {
      return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: AppColors.warning,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Warning',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Canceling will lose the connection. Continue?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOutlinedButton(
                              'No',
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _buildGradientButton(
                              'Yes',
                              color: AppColors.error,
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ) ??
          false;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with kiosk buttons
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.accentBlue,
                                      AppColors.accentTeal
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.dns_rounded,
                                  color: AppColors.white,
                                  size: 16.sp,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Database Settings',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Configure SQL Server connection',
                                      style: TextStyle(
                                        fontSize: 6.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Kiosk mode buttons
                              _buildKioskButton(
                                icon: Icons.lock_outline_rounded,
                                label: 'Kiosk',
                                color: AppColors.success,
                                onTap: () async {
                                  await startKioskMode();
                                  Navigator.of(context).pop();
                                  _showModernSnackBar(
                                      context, 'Kiosk Mode Enabled',
                                      isError: false);
                                },
                              ),
                              SizedBox(width: 6.w),
                              _buildKioskButton(
                                icon: Icons.lock_open_rounded,
                                label: 'Exit',
                                color: AppColors.error,
                                onTap: () async {
                                  await stopKioskMode();
                                  Navigator.of(context).pop();
                                  _showModernSnackBar(
                                      context, 'Kiosk Mode Disabled',
                                      isError: true);
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),

                          // Form fields - 2x2 grid
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: serverController,
                                  hintText: 'Server IP',
                                  icon: Icons.computer_rounded,
                                  hasError: fieldErrors['server']!,
                                  autofocus: true,
                                  onChanged: (_) {
                                    if (fieldErrors['server']!) {
                                      setState(() {
                                        fieldErrors['server'] = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: databaseController,
                                  hintText: 'Database',
                                  icon: Icons.storage_rounded,
                                  hasError: fieldErrors['database']!,
                                  onChanged: (_) {
                                    if (fieldErrors['database']!) {
                                      setState(() {
                                        fieldErrors['database'] = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildValidatedTextField(
                                  controller: usernameController,
                                  hintText: 'Username',
                                  icon: Icons.person_rounded,
                                  hasError: fieldErrors['username']!,
                                  onChanged: (_) {
                                    if (fieldErrors['username']!) {
                                      setState(() {
                                        fieldErrors['username'] = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildPasswordField(
                                  controller: passwordController,
                                  hintText: 'Password',
                                  hasError: fieldErrors['password']!,
                                  isPasswordVisible: isPasswordVisible,
                                  onToggleVisibility: () {
                                    setState(() {
                                      isPasswordVisible = !isPasswordVisible;
                                    });
                                  },
                                  onChanged: (_) {
                                    if (fieldErrors['password']!) {
                                      setState(() {
                                        fieldErrors['password'] = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildOutlinedButton(
                                  'Connect',
                                  icon: Icons.wifi_tethering_rounded,
                                  onPressed: () async {
                                    bool status =
                                        await testConnection(context, setState);
                                    Provider.of<ConnectionProvider>(context,
                                            listen: false)
                                        .updateConnectionStatus(status);
                                  },
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _buildOutlinedButton(
                                  'Cancel',
                                  onPressed: () async {
                                    if (connect) {
                                      bool proceed =
                                          await showCancelWarning(context);
                                      if (proceed) {
                                        Navigator.of(context).pop();
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        await prefs.clear();
                                        Provider.of<ConnectionProvider>(context,
                                                listen: false)
                                            .updateConnectionStatus(false);
                                        _showModernSnackBar(
                                            context, 'Connection lost',
                                            isError: true);
                                      }
                                    } else {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _buildGradientButton(
                                  'Save',
                                  icon: Icons.save_rounded,
                                  enabled: connect,
                                  onPressed: connect
                                      ? () async {
                                          await _handleUpdate(
                                            context,
                                            serverController,
                                            databaseController,
                                            usernameController,
                                            passwordController,
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Validated text field with error state
  static Widget _buildValidatedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool hasError,
    bool autofocus = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: hasError
                ? AppColors.error.withValues(alpha: 0.08)
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.divider,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 8.sp,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 8.sp,
                color: hasError ? AppColors.error : AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                icon,
                size: 14.sp,
                color: hasError ? AppColors.error : AppColors.accentBlue,
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(left: 8.w, top: 4.h),
            child: Text(
              'This field is required',
              style: TextStyle(
                fontSize: 6.sp,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  // Password field with visibility toggle
  static Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool hasError,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: hasError
                ? AppColors.error.withValues(alpha: 0.08)
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.divider,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: !isPasswordVisible,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 8.sp,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 8.sp,
                color: hasError ? AppColors.error : AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.lock_rounded,
                size: 14.sp,
                color: hasError ? AppColors.error : AppColors.accentBlue,
              ),
              suffixIcon: GestureDetector(
                onTap: onToggleVisibility,
                child: Icon(
                  isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(left: 8.w, top: 4.h),
            child: Text(
              'This field is required',
              style: TextStyle(
                fontSize: 6.sp,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildOutlinedButton(
    String text, {
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12.sp),
              SizedBox(width: 4.w),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildGradientButton(
    String text, {
    VoidCallback? onPressed,
    IconData? icon,
    Color? color,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: color != null
                    ? [color, color.withValues(alpha: 0.8)]
                    : [AppColors.accentBlue, AppColors.accentTeal],
              )
            : null,
        color: enabled ? null : AppColors.divider,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: (color ?? AppColors.accentBlue).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12.sp),
                SizedBox(width: 4.w),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildKioskButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12.sp),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 6.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showModernSnackBar(BuildContext context, String message,
      {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: AppColors.white,
              size: 14.sp,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(12.r),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<void> _handleUpdate(
    BuildContext context,
    TextEditingController serverController,
    TextEditingController databaseController,
    TextEditingController usernameController,
    TextEditingController passwordController,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (serverController.text.isNotEmpty &&
        databaseController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      prefs.setString('serverIp', serverController.text);
      prefs.setString('database', databaseController.text);
      prefs.setString('userName', usernameController.text);
      prefs.setString('password', passwordController.text);
      Navigator.of(context).pop();
      _showModernSnackBar(context, 'Settings saved successfully',
          isError: false);
    } else {
      _showModernSnackBar(context, 'All fields are required', isError: true);
    }
  }

  static void startPopupTimeout(BuildContext context,
      {required Duration duration}) {
    _popupTimer?.cancel();

    _popupTimer = Timer(duration, () {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        _showModernSnackBar(context, 'Popup closed due to inactivity',
            isError: false);
      }
    });
  }

  static void resetPopupTimeout(BuildContext context,
      {required Duration duration}) {
    _popupTimer?.cancel();
    startPopupTimeout(context, duration: duration);
  }
}
