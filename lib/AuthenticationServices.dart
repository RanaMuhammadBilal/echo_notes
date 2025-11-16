import 'package:local_auth/local_auth.dart';

class AuthenticationServices{
final LocalAuthentication localAuthentication = LocalAuthentication();

Future<bool> authenticateLocally() async{
  bool isAuthenticated = false;
  try{
    isAuthenticated = await localAuthentication.authenticate(localizedReason: "Please authenticate to continue",
        options: AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        )
    );
  }catch(ex){
    print('Error : $ex');
  }

  return isAuthenticated;
}
}