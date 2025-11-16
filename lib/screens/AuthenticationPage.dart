import 'package:echo_notes/AuthenticationServices.dart';
import 'package:echo_notes/screens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AuthenticationPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => AuthenticationPageState();

}


class AuthenticationPageState extends State<AuthenticationPage>{

  @override
  void initState() {
    super.initState();
    biometric();
  }

  void biometric() async{
    bool check = await AuthenticationServices().authenticateLocally();
    if(check){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IconButton(onPressed: (){
          biometric();
        }, icon: Icon(Icons.fingerprint, size: 60,)),
      ),
    );
  }

}