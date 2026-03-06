import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/table_provider.dart';
import 'providers/order_provider.dart';
import 'providers/report_provider.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const PRM393CoffeeApp());
}

class PRM393CoffeeApp extends StatelessWidget {
  const PRM393CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
