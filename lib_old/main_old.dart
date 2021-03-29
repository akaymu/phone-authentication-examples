import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import the firebase_core plugin
import 'package:firebase_core/firebase_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  // Create the initialization Future outside of `build`:
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        // Initialize FlutterFire:
        future: _initialization,
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return SomethingWentWrong();
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return LoginScreen();
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return Loading();
        },
      ),
    );
  }
}

class SomethingWentWrong extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Error Screen'),
      ),
    );
  }
}

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _phoneNumberController = TextEditingController();
  String prevPhoneNumber = '';

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xffF2F2F2),
      body: Column(children: [
        Spacer(flex: 2),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.25),
          child: Image.asset('assets/images/logo.png'),
        ),
        Spacer(flex: 1),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                    style: const TextStyle(
                        color: const Color(0xff19003a),
                        fontWeight: FontWeight.w700,
                        fontFamily: "Montserrat",
                        fontStyle: FontStyle.normal,
                        fontSize: 21.0),
                    text: "Ücretsiz "),
                TextSpan(
                    style: const TextStyle(
                        color: const Color(0xff19003a),
                        fontWeight: FontWeight.w500,
                        fontFamily: "Montserrat",
                        fontStyle: FontStyle.normal,
                        fontSize: 21.0),
                    text: " giriş için telefon numaranızı giriniz.")
              ],
            ),
          ),
        ),
        Spacer(flex: 1),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.10),
          child: SizedBox(
            height: 45,
            child: TextField(
              controller: _phoneNumberController,
              maxLength: 12,
              style: TextStyle(
                fontSize: 22,
                letterSpacing: 1.2,
                color: Colors.blueAccent,
              ),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                prefix: Text(" +90 5"),
                prefixStyle: TextStyle(fontSize: 22, letterSpacing: 1.2, color: Colors.blueAccent),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                    borderSide: BorderSide(color: Color(0xffCCCCCC))),
              ),
              onChanged: (String value) {
                if (value.length == 0) {
                  prevPhoneNumber = '';
                }

                if (value.length == 2 || value.length == 6 || value.length == 9) {
                  String modifiedValue;
                  if (prevPhoneNumber.length != 3 &&
                      prevPhoneNumber.length != 7 &&
                      prevPhoneNumber.length != 10) {
                    modifiedValue = value + ' ';
                  } else {
                    int valueLength = value.length;
                    modifiedValue = value.substring(0, valueLength - 1);
                  }

                  _phoneNumberController.text = modifiedValue;
                  _phoneNumberController.selection = TextSelection.fromPosition(
                    TextPosition(offset: modifiedValue.length),
                  );
                }

                prevPhoneNumber = _phoneNumberController.text;
              },
            ),
          ),
        ),
        Spacer(flex: 1),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.10),
          child: SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style:
                  ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xff19003A))),
              onPressed: () async {
                String phoneNumber = '+90 5' + _phoneNumberController.text;
                FirebaseAuth auth = FirebaseAuth.instance;
                if (auth != null) {
                  print('auth NOT null');
                } else {
                  print('auth NULL');
                }
                await auth.signOut();
                await auth.verifyPhoneNumber(
                  phoneNumber: phoneNumber,
                  verificationCompleted: (PhoneAuthCredential credential) async {
                    print('Phone Authentication: Verification Completed');
                    print(credential.toString());
                    await auth.signInWithCredential(credential);
                  },
                  verificationFailed: (FirebaseAuthException e) {
                    print('Phone Authentication: Verification Failed');
                    print(e.code);
                    if (e.code == 'invalid-phone-number') {
                      print('The provided phone number is not valid.');
                    }
                  },
                  codeSent: (String verificationId, int resendToken) async {
                    print('Phone Authentication: Code Sent STARTED');
                    print(verificationId + ': ' + resendToken.toString());
                    // Update the UI - wait for the user to enter the SMS code
                    String smsCode = '123457';

                    print('Phone Authentication: Code Sent 1');
                    // Create a PhoneAuthCredential with the code
                    PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
                        verificationId: verificationId, smsCode: smsCode);

                    print('Phone Authentication: Code Sent 2');

                    if (phoneAuthCredential != null) {
                      print('phoneAuthCredential NULL');
                    } else {
                      print('phoneAuthCredential NOT null');
                    }

                    // Sign the user in (or link) with the credential
                    final UserCredential credential =
                        await auth.signInWithCredential(phoneAuthCredential);
                    print('Phone Authentication: Code Sent 3');
                    if (credential != null) {
                      // print('Credential: ' + credential.toString());
                    }
                    print('Phone Authentication: Code Sent 4');
                    if (auth.currentUser != null) {
                      //print('Current User: ' + auth.currentUser.toString());
                      // print('Id Token: ' + (await auth.currentUser.getIdToken()));
                    }

                    print('Phone Authentication: Code Sent ENDED');
                  },
                  codeAutoRetrievalTimeout: (String verificationId) {
                    print('Phone Authentication: Retrieval Timeout');
                    print(verificationId);
                    print('Default Code Retrieve Timeout has been reached');
                  },
                );
              },
              child: Text(
                "GİRİŞ",
                style: TextStyle(fontSize: 26, color: Colors.white),
              ),
            ),
          ),
        ),
        Spacer(flex: 10),
      ]),
    );
  }

  @override
  void dispose() {
    _phoneNumberController.clear();
    super.dispose();
  }
}
