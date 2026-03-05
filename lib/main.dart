import 'package:echo_notes/AuthenticationProvider.dart';
import 'package:echo_notes/ThemeProvider.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:echo_notes/screens/AuthenticationPage.dart';
import 'package:echo_notes/screens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notesBox');
  await Hive.openBox('settings');
  await Hive.openBox('categoryBox');
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => NotesProvider()),
      ChangeNotifierProvider(create: (_)=> ThemeProvider()),
      ChangeNotifierProvider(create: (_)=>AuthenticationProvider()),
    ], child: MyApp(),),

  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We watch the provider to rebuild whenever saveTheme is called
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // This is where the magic happens:
      theme: themeProvider.getThemeData(),
      // ADD THESE LINES BELOW:
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // This is the one the error is asking for:
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        // Add other languages if you need them
      ],
      home: context.watch<AuthenticationProvider>().getAuthenticationValue()
          ?  AuthenticationPage()
          :  HomePage(),
    );
  }
}

