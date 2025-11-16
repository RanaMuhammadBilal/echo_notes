import 'package:echo_notes/AuthenticationProvider.dart';
import 'package:echo_notes/ThemeProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => SettingsState();

}

class SettingsState extends State<Settings>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_rounded),
            SizedBox(width: 10),
            Text('Settings'),
            SizedBox(width: 70),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<ThemeProvider>(builder: (context,provider, __){
        return Column(
          children: [
            SwitchListTile.adaptive(
                value: provider.getThemeValue(),
                onChanged: (value) async{
                  await provider.saveTheme(value: !provider.getThemeValue());
                },
              title: Text('Dark Mode'),
              subtitle: Text('Change Theme Mode here'),

            ),
            Consumer<AuthenticationProvider>(builder: (context, provider, _){
              return SwitchListTile.adaptive(
                value: provider.getAuthenticationValue(),
                onChanged: (value) async{
                  await provider.saveAuthentication(value: !provider.getAuthenticationValue());
                },
                title: Text('Biometric Verification'),
                subtitle: Text('Change Verification Mode here'),

              );
            })


          ],
        );
      })
    );
  }

}