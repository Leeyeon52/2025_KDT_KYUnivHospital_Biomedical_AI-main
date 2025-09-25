import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import 'dart:convert'; // utf8

class RegisterScreen extends StatefulWidget {
  final String baseUrl;

  const RegisterScreen({super.key, required this.baseUrl});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _selectedGender = 'M';
  String _selectedRole = 'P';
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  final List<int> _yearList =
      List.generate(141, (index) => DateTime.now().year - index);
  final List<int> _monthList = List.generate(12, (index) => index + 1);

  bool _isDuplicate = true;
  bool _isIdChecked = false;

  static const Color primaryBlue = Color(0xFF3869A8);
  static const Color lightBlueBackground = Color(0xFFB4D4FF);

  static const Color patientRoleColor = Color(0xFF90CAF9);
  static const Color doctorRoleColor = Color(0xFF81C784);
  static const Color unselectedCardColor = Color(0xFFE0E0E0);

  static const double _itemHeight = 48;
  static const double _menuMaxHeight = 260;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _registerIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicateId() async {
    final viewModel = context.read<AuthViewModel>();
    final id = _registerIdController.text.trim();

    if (id.length < 4) {
      _showSnack('아이디는 최소 4자 이상이어야 합니다');
      setState(() {
        _isIdChecked = false;
        _isDuplicate = true;
      });
      return;
    }

    final exists = await viewModel.checkUserIdDuplicate(id, _selectedRole);
    setState(() {
      _isIdChecked = true;
      _isDuplicate = (exists ?? true);
    });

    if (viewModel.duplicateCheckErrorMessage != null) {
      _showSnack(viewModel.duplicateCheckErrorMessage!);
    } else if (exists == false) {
      _showSnack('사용 가능한 아이디입니다');
    } else {
      _showSnack('이미 사용 중인 아이디입니다');
    }
  }

  Future<void> _submit() async {
    String? _validateBirth() {
      if (_selectedYear == null || _selectedMonth == null || _selectedDay == null) {
        return '생년월일을 모두 선택해주세요';
      }
      final birthDate = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
      final now = DateTime.now();
      final oldest = DateTime(now.year - 125, now.month, now.day);
      if (birthDate.isBefore(oldest) || birthDate.isAfter(now)) {
        return '유효한 생년월일을 입력해주세요';
      }
      return null;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnack('모든 필드를 올바르게 입력해주세요.');
      return;
    }
    final birthError = _validateBirth();
    if (birthError != null) {
      _showSnack(birthError);
      return;
    }
    if (!_isIdChecked || _isDuplicate) {
      _showSnack('아이디 중복 확인을 완료해주세요.');
      return;
    }

    final userData = {
      'register_id': _registerIdController.text.trim(),
      'password': _passwordController.text.trim(),
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'birth':
          '${_selectedYear!}-${_selectedMonth!.toString().padLeft(2, '0')}-${_selectedDay!.toString().padLeft(2, '0')}',
      'phone': _phoneController.text.trim(),
      'role': _selectedRole,
    };

    final viewModel = context.read<AuthViewModel>();
    final error = await viewModel.registerUser(userData);

    if (error == null) {
      _showSnack('회원가입 성공!');
      context.go('/login');
    } else {
      _showSnack(error);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildYearDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: false),
      child: DropdownButtonFormField<int>(
        value: _selectedYear,
        isExpanded: true,
        isDense: true,
        itemHeight: _itemHeight,
        menuMaxHeight: _menuMaxHeight,
        icon: const Icon(Icons.arrow_drop_down),
        decoration: const InputDecoration(
          labelText: '연도',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 14),
        items: _yearList
            .map((y) => DropdownMenuItem<int>(value: y, child: Text('$y')))
            .toList(),
        onChanged: (v) => setState(() => _selectedYear = v),
        validator: (v) => v == null ? '연도를 선택해주세요' : null,
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: false),
      child: DropdownButtonFormField<int>(
        value: _selectedMonth,
        isExpanded: true,
        isDense: true,
        itemHeight: _itemHeight,
        menuMaxHeight: _menuMaxHeight,
        icon: const Icon(Icons.arrow_drop_down),
        decoration: const InputDecoration(
          labelText: '월',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 14),
        items: _monthList
            .map((m) => DropdownMenuItem<int>(value: m, child: Text('$m')))
            .toList(),
        onChanged: (v) {
          setState(() {
            _selectedMonth = v;
            _selectedDay = null;
          });
        },
        validator: (v) => v == null ? '월을 선택해주세요' : null,
      ),
    );
  }

  Widget _buildDayDropdown() {
    int maxDay = 31;
    if (_selectedYear != null && _selectedMonth != null) {
      maxDay = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
    }
    final days = List.generate(maxDay, (index) => index + 1);

    return Theme(
      data: Theme.of(context).copyWith(useMaterial3: false),
      child: DropdownButtonFormField<int>(
        value: _selectedDay,
        isExpanded: true,
        isDense: true,
        itemHeight: _itemHeight,
        menuMaxHeight: _menuMaxHeight,
        icon: const Icon(Icons.arrow_drop_down),
        decoration: const InputDecoration(
          labelText: '일',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 14),
        items: days
            .map((d) => DropdownMenuItem<int>(value: d, child: Text('$d')))
            .toList(),
        onChanged: (v) => setState(() => _selectedDay = v),
        validator: (v) => v == null ? '일을 선택해주세요' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: lightBlueBackground,
      appBar: AppBar(
        title: const Text('회원가입', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: kIsWeb
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: _buildFormCard(authViewModel),
                )
              : _buildFormCard(authViewModel),
        ),
      ),
    );
  }

  Widget _buildFormCard(AuthViewModel authViewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _roleSelectionCard('환자', 'P', Icons.personal_injury_outlined),
                const SizedBox(width: 15),
                _roleSelectionCard('의사', 'D', Icons.medical_information_outlined),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              _nameController,
              '이름 (한글만)',
              inputFormatters: [_NameByteLimitFormatter()],
            ),
            const SizedBox(height: 10),
            _buildGenderSelectionButtons(),
            Row(
              children: [
                Expanded(child: _buildYearDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _buildMonthDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _buildDayDropdown()),
              ],
            ),
            _buildTextField(
              _phoneController,
              '전화번호',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                _PhoneNumberFormatter(),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _registerIdController,
                    '아이디 (4자 이상)',
                    onChanged: (_) {
                      setState(() {
                        _isIdChecked = false;
                        _isDuplicate = true;
                        authViewModel.clearDuplicateCheckErrorMessage();
                      });
                    },
                    errorText: authViewModel.duplicateCheckErrorMessage,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: authViewModel.isCheckingUserId ? null : _checkDuplicateId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white, // ✅ 글씨 흰색
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: authViewModel.isCheckingUserId
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          '중복확인',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
            _buildTextField(
              _passwordController,
              '비밀번호 (6자 이상)',
              isPassword: true,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
            ),
            _buildTextField(
              _confirmController,
              '비밀번호 확인',
              isPassword: true,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white, // ✅ 글씨 흰색
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  '회원가입 완료',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label을 입력해주세요';
          if (label == '비밀번호 확인' && value != _passwordController.text) {
            return '비밀번호가 일치하지 않습니다';
          }
          if (label == '이름 (한글만)' && !RegExp(r'^[가-힣]+$').hasMatch(value)) {
            return '이름은 한글만 입력해주세요';
          }
          return null;
        },
      ),
    );
  }

  Widget _roleSelectionCard(String label, String roleValue, IconData icon) {
    final isSelected = _selectedRole == roleValue;

    Color cardBackgroundColor = isSelected
        ? (roleValue == 'P' ? patientRoleColor : doctorRoleColor)
        : unselectedCardColor;

    Color iconAndTextColor = isSelected ? Colors.white : Colors.grey[700]!;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = roleValue;
            _isIdChecked = false;
            _isDuplicate = true;
            _registerIdController.clear();
            context.read<AuthViewModel>().clearDuplicateCheckErrorMessage();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: isSelected ? 3 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? cardBackgroundColor.withOpacity(0.6)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: iconAndTextColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 17,
                  color: iconAndTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelectionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _genderSelectionButton('남', 'M', Colors.blue[700]!),
          const SizedBox(width: 10),
          _genderSelectionButton('여', 'F', Colors.red[400]!),
        ],
      ),
    );
  }

  Widget _genderSelectionButton(String label, String genderValue, Color color) {
    final isSelected = _selectedGender == genderValue;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedGender = genderValue),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) const Icon(Icons.check, size: 20),
            if (isSelected) const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameByteLimitFormatter extends TextInputFormatter {
  final int maxBytes;
  _NameByteLimitFormatter({this.maxBytes = 18});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text;
    final bytes = utf8.encode(newText);
    if (bytes.length <= maxBytes) return newValue;

    int byteCount = 0;
    int cutoffIndex = 0;
    for (int i = 0; i < newText.length; i++) {
      final char = newText[i];
      final charBytes = utf8.encode(char);
      if (byteCount + charBytes.length > maxBytes) break;
      byteCount += charBytes.length;
      cutoffIndex = i + 1;
    }

    final truncated = newText.substring(0, cutoffIndex);
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', '');
    if (text.length > 11) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 || i == 6) {
        if (text.length > i + 1) buffer.write('-');
      }
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}