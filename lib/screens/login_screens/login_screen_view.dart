import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/helper/network_helper.dart';
import 'package:geofence_demo/models/base_model.dart';
import 'package:geofence_demo/screens/home_screen/home_screen.dart';

import '../../helper/permission_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
  TextEditingController(text: NetworkService.demoEmail);
  final TextEditingController _passwordController =
  TextEditingController(text: NetworkService.demoPassword);

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final allowed = await PermissionHelper.checkLocationPermission(context);
    if (!allowed) return;
    setState(() => _isLoading = true);
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 1,
        persist: false,
      );
      final lat = location.coords.latitude;
      final lng = location.coords.longitude;

      final result = await NetworkService().request<BaseModel>(
        endpoint: "login",
        method: HttpMethod.post,
        data: {
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "lat": lat,
          "lng": lng,
          "browser_id": DateTime.now().millisecondsSinceEpoch, // random ID
        },
        fromJson: (json) => BaseModel.fromJson(json),
      );
      setState(() => _isLoading = false);
      if (result.success ?? false) {
        await appStorage.setAuthToken(result.token ?? "");
        await appStorage.setIsLogin(true);
        await appStorage.setUserId(result.userId ?? 0);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? "Login failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: "Email / Username",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Please enter email" : null,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Please enter password" : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
