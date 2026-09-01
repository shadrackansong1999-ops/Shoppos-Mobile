import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/app_state.dart';
import 'core/providers/cart_provider.dart';
import 'core/theme.dart';
import 'ui/screens/boot/boot_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShopPosApp());
}

class ShopPosApp extends StatelessWidget {
  const ShopPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..bootstrap()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'ShopPOS Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const BootGate(),
      ),
    );
  }
}
