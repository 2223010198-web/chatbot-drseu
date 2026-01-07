import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'features/auth/login_screen.dart'; // YA NO LO NECESITAMOS
// import 'services/auth_service.dart';      // YA NO LO NECESITAMOS
import 'features/cursos/courses_list_screen.dart';

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
      // --- CAMBIO PRINCIPAL: Vamos directo al Layout ---
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
    Center(child: Text("Vista Matriculados (Próximamente)")),
    CoursesListScreen(),
    Center(child: Text("Dashboard Analítica")),
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
        destinations: [
          NavigationDestination(icon: Icon(Icons.people), label: 'Matriculados'),
          NavigationDestination(icon: Icon(Icons.edit_calendar), label: 'Gestión'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Analítica'),
        ],
      ),
    );
  }
}