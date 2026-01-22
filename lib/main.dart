import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// 1. IMPORTANTE: Importar paquete de localización
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/cursos/courses_list_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización simple para Database
  try {
    await Firebase.initializeApp();
    print("✅ Firebase conectado");
  } catch (e) {
    print("❌ Error Firebase: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin DRSU',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),

      // --- 2. CONFIGURACIÓN DE IDIOMA (SOLUCIÓN ERROR ROJO) ---
      // Esto permite que el DatePicker y TimePicker sepan cómo dibujar el español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español (Principal)
        Locale('en', 'US'), // Inglés (Respaldo)
      ],
      // --------------------------------------------------------

      home: MainLayout(),
    );
  }
}

// --- LAYOUT PRINCIPAL CON NAVBAR ---
class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1; // Empezamos en Gestión (Centro)

  final List<Widget> _pages = [
    // Placeholder para la vista de matriculados
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text("Vista Matriculados", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("(Próximamente)", style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
    CoursesListScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: 'Matriculados'),
          NavigationDestination(icon: Icon(Icons.edit_calendar), label: 'Gestión'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Analítica'),
        ],
      ),
    );
  }
}