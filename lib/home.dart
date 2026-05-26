import 'dart:convert';
import 'package:deep_pick/deep_pick.dart';
import 'package:flutter/services.dart';
import 'package:goten/model/employee.dart';
import 'package:goten/model/unit.dart';
import 'package:goten/widgets/dialogs.dart';
import 'dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'utils/device_utils.dart';
import 'dart:io' show Platform;
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/absensi_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String? _deviceId;
  String? _kdUnit;
  String? _karNama;
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers untuk TypeAhead
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _employeeController = TextEditingController();

  // Selected items
  Units? _selectedUnit;
  Employee? _selectedEmployee;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _initPlatformState();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _unitController.dispose();
    _employeeController.dispose();
    super.dispose();
  }

  Future<void> _initPlatformState() async {
    try {
      String? deviceId = await DeviceUtils.getDeviceId();
      if (deviceId == null) {
        deviceId = 'Failed to get deviceId.';
      }

      if (mounted) {
        setState(() {
          _deviceId = deviceId;
          _isLoading = false;
        });

        // Start animations
        _fadeController.forward();
        await Future.delayed(Duration(milliseconds: 200));
        _slideController.forward();
      }
    } catch (e) {
      print('Error getting device ID: $e');
      if (mounted) {
        setState(() {
          _deviceId = 'Failed to get deviceId.';
          _isLoading = false;
        });
        _fadeController.forward();
        _slideController.forward();
      }
    }
  }

  // Load units using API service
  Future<List<Units>> _getUnits(String query) async {
    try {
      final response = await ApiService.get(AppConfig.unitEndpoint);

      if (response != null && response['data'] != null) {
        List allUnits = response['data'];
        List<Units> unitsModels = [];

        allUnits.forEach((element) {
          unitsModels.add(Units(
            kdUnit: element['kd_unit']?.toString() ?? '',
            nmUnit: element['nm_unit']?.toString() ?? '',
            latitude: element['latitude'] != null
                ? double.tryParse(element['latitude'].toString()) ?? 0.0
                : 0.0,
            longitude: element['longitude'] != null
                ? double.tryParse(element['longitude'].toString()) ?? 0.0
                : 0.0,
          ));
        });

        return unitsModels.where((unit) =>
            unit.nmUnit.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    } catch (e) {
      print('Error loading units: $e');
    }
    return [];
  }

  // Load employees using API service
  Future<List<Employee>> _getEmployees(String query) async {
    if (_kdUnit == null) return [];

    try {
      final response = await ApiService.get(AppConfig.karyawanByUnit(_kdUnit!));

      if (response != null && response['data'] != null) {
        List allEmployee = response['data'];
        List<Employee> employeeModels = [];

        allEmployee.forEach((element) {
          employeeModels.add(Employee(karNama: element['kar_nama']));
        });

        return employeeModels.where((employee) =>
            employee.karNama.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    } catch (e) {
      print('Error loading employees: $e');
    }
    return [];
  }

  // Registration using service
  Future<void> _doRegist() async {
    if (_kdUnit == null || _karNama == null || _deviceId == null) {
      _showMessage('Data tidak lengkap', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await AbsensiService.doRegistrasi(
        kdUnit: _kdUnit!,
        karNama: _karNama!,
        deviceId: _deviceId!,
      );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else {
        _showMessage("Registrasi gagal. Silakan coba lagi.", isError: true);
      }
    } catch (e) {
      print('Registration error: $e');
      _showMessage("Terjadi kesalahan saat registrasi", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat aplikasi...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(height: 20),

                  // Header Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildHeader(),
                  ),

                  SizedBox(height: 20),

                  // Registration Card
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildRegistrationCard(),
                  ),

                  SizedBox(height: 60),

                  // Company branding
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildFooter(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      child: Column(
        children: [
          // Logo placeholder - you can add your logo here
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.business,
              size: 50,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 18),

          Text(
            "GOTEN",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              letterSpacing: 2.0,
            ),
          ),

          // SizedBox(height: 8),
          //
          // Text(
          //   "Sistem Absensi Digital",
          //   style: TextStyle(
          //     fontSize: 16,
          //     color: Colors.grey.shade600,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
          //
          // SizedBox(height: 4),
          //
          // Text(
          //   "Registrasi perangkat Anda",
          //   style: TextStyle(
          //     fontSize: 14,
          //     color: Colors.grey.shade500,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.app_registration,
                color: Colors.blue.shade600,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                "Registrasi Perangkat",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          Text(
            "Lengkapi data di bawah untuk menggunakan aplikasi",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          SizedBox(height: 32),

          // Unit Selection
          _buildFormField(
            label: "Pilih Unit",
            icon: Icons.business,
            child: _buildUnitTypeAhead(),
          ),

          SizedBox(height: 24),

          // Employee Selection
          _buildFormField(
            label: "Pilih Nama Karyawan",
            icon: Icons.person,
            child: _buildEmployeeTypeAhead(),
          ),

          SizedBox(height: 40),

          // Registration Button
          _buildRegistrationButton(),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildUnitTypeAhead() {
    return TypeAheadField<Units>(
      controller: _unitController,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.business, color: Colors.grey.shade600),
            hintText: 'Ketik untuk mencari unit...',
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
      },
      suggestionsCallback: (pattern) async {
        return await _getUnits(pattern);
      },
      itemBuilder: (context, Units suggestion) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_city,
                  size: 20,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.nmUnit,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (suggestion.kdUnit != null)
                      Text(
                        'Kode: ${suggestion.kdUnit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      onSelected: (Units suggestion) {
        setState(() {
          _selectedUnit = suggestion;
          _kdUnit = suggestion.kdUnit;
          _karNama = null;
          _selectedEmployee = null;
          _employeeController.clear();
        });
        _unitController.text = suggestion.nmUnit;
      },
    );
  }

  Widget _buildEmployeeTypeAhead() {
    if (_kdUnit == null) {
      return Container(
        height: 56,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: Colors.grey.shade400),
            SizedBox(width: 12),
            Text(
              'Pilih unit terlebih dahulu',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return TypeAheadField<Employee>(
      controller: _employeeController,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
            hintText: 'Ketik untuk mencari nama...',
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
      },
      suggestionsCallback: (pattern) async {
        return await _getEmployees(pattern);
      },
      itemBuilder: (context, Employee suggestion) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion.karNama,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onSelected: (Employee suggestion) {
        setState(() {
          _selectedEmployee = suggestion;
          _karNama = suggestion.karNama;
        });
        _employeeController.text = suggestion.karNama;
      },
    );
  }

  Widget _buildRegistrationButton() {
    bool isEnabled = _kdUnit != null && _karNama != null && !_isSubmitting;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? _doRegist : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.transparent : Colors.grey.shade300,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Memproses...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.app_registration,
              color: isEnabled ? Colors.white : Colors.grey.shade600,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Mulai Menggunakan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            "assets/bsm.png",
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 12),
        Text(
          "PT Bumi Sarana Maju",
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        // SizedBox(height: 4),
        // Text(
        //   "Sistem Absensi Digital v1.0",
        //   style: TextStyle(
        //     fontSize: 12,
        //     color: Colors.grey.shade500,
        //   ),
        // ),
      ],
    );
  }
}