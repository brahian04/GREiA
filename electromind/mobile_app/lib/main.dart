import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:electromind_app/config/constants.dart';
import 'package:electromind_app/config/routes.dart';
import 'core/utils/timeago_setup.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/tickets/presentation/cubit/tickets_cubit.dart';
import 'features/clients/presentation/cubit/clients_cubit.dart';
import 'features/ai/presentation/cubit/ai_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await di.init();

  setupTimeago();

  runApp(const GreiaApp());
}

class GreiaApp extends StatelessWidget {
  const GreiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthCubit>()),
        BlocProvider(create: (_) => di.sl<TicketsCubit>()),
        BlocProvider(create: (_) => di.sl<ClientsCubit>()),
        BlocProvider(create: (_) => di.sl<AiCubit>()),
      ],
      child: MaterialApp.router(
        title: 'GREiA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00BFA5),
            brightness: Brightness.light,
            primary: const Color(0xFF00BFA5), // Teal
            secondary: const Color(0xFF64FFDA),
          ),
          scaffoldBackgroundColor:
              const Color(0xFFF5F5F7), // Soft grey used in iOS
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
            iconTheme: IconThemeData(color: Colors.black87),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFFEEEEEE)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // Or light grey
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.grey),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00BFA5),
            secondary: Color(0xFF64FFDA),
            surface: Color(0xFF1E1E1E),
            error: Color(0xFFCF6679),
            onPrimary: Colors.black,
            onSurface: Color(0xFFE0E0E0),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            iconTheme: IconThemeData(color: Colors.white70),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E1E),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
            ),
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIconColor: Colors.grey.shade500,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 16),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF00BFA5),
            foregroundColor: Colors.black,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
