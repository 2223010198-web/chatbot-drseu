import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart'; // Crearemos un placeholder abajo
import 'services/auth_service.dart';
import 'features/cursos/courses_list_screen.dart';
// --- CONFIGURACIÓN DE FIREBASE ---
// (Si sigues usando la configuración manual, pégala aquí dentro del main)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intenta la inicialización automática primero
  try {
    await Firebase.initializeApp();
    print("✅ Firebase inicializado automáticamente (Leyendo JSON)");
  } catch (e) {
    print("❌ Error en init automático: $e");
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
      // StreamBuilder escucha cambios en la autenticación
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return MainLayout(); // Si hay usuario, vamos al Dashboard
          }
          return LoginScreen(); // Si no, al Login
        },
      ),
    );
  }
}

// --- LAYOUT PRINCIPAL CON NAVBAR ---
class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1; // Empezamos en el centro (Gestión)

  // Aquí definiremos las 3 vistas principales
  final List<Widget> _pages = [
    Center(child: Text("Vista Matriculados (Próximamente)")), // Index 0
    CoursesListScreen(),                                      // Index 1 (NUESTRO GESTOR)
    Center(child: Text("Dashboard Analítica")),               // Index 2
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