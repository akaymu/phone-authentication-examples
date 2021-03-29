import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'homepage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Authentication',
      routes: <String, WidgetBuilder>{
        '/homepage': (BuildContext context) => HomePage(),
        '/loginpage': (BuildContext context) => MyApp(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: _initialization,
        builder: (BuildContext context, AsyncSnapshot<FirebaseApp> snapshot) {
          if (snapshot.hasData) {
            return MyAppPage(title: 'Phone Authentication');
          }

          return Container();
        },
      ),
    );
  }
}

class MyAppPage extends StatefulWidget {
  MyAppPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyAppPageState createState() => _MyAppPageState();
}

class _MyAppPageState extends State<MyAppPage> {
  String phoneNo;
  String smsOTP;
  String verificationId;
  String errorMessage = '';
  FirebaseAuth _auth = FirebaseAuth.instance;

  void smsOTPSent(String verId, [int forceCodeResend]) {
    print('EDICT-DIGITAL: ' + 'SMS OTP Sent');
    print('Verification Id: ' + verId);
    this.verificationId = verId;
    smsOTPDialog(context).then((value) {
      print('sign in');
    });
  }

  Future<void> verifyPhone() async {
    try {
      await _auth.verifyPhoneNumber(
          phoneNumber: this.phoneNo, // PHONE NUMBER TO SEND OTP
          codeAutoRetrievalTimeout: (String verId) {
            print('EDICT-DIGITAL: ' + 'Retrieval Timeout');
            //Starts the phone number verification process for the given phone number.
            //Either sends an SMS with a 6 digit code to the phone number specified, or sign's the user in and [verificationCompleted] is called.
            this.verificationId = verId;
          },
          codeSent: (String veriId, int someInt) =>
              smsOTPSent(veriId, someInt), // WHEN CODE SENT THEN WE OPEN DIALOG TO ENTER OTP.
          timeout: const Duration(seconds: 30),
          verificationCompleted: (AuthCredential phoneAuthCredential) {
            print('EDICT-DIGITAL: ' + 'Verification Completed');
            print('PhoneAuthCredential: ' + phoneAuthCredential.toString());
          },
          verificationFailed: (FirebaseAuthException exceptio) {
            print('EDICT-DIGITAL: ' + 'Verification Failed');
            print('${exceptio.message}');
          });
    } catch (e) {
      handleError(e);
    }
  }

  Future<bool> smsOTPDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Enter SMS Code'),
            content: Container(
              height: 85,
              child: Column(children: [
                TextField(
                  onChanged: (value) {
                    this.smsOTP = value;
                  },
                ),
                (errorMessage != ''
                    ? Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      )
                    : Container())
              ]),
            ),
            contentPadding: EdgeInsets.all(10),
            actions: <Widget>[
              FlatButton(
                child: Text('Done'),
                onPressed: () {
                  User user = _auth.currentUser;
                  // print('EDICT-DIGITAL: User: ' + (user != null ? user.toString() : ''));

                  if (user != null) {
                    print('EDICT-DIGITAL: User: null DEĞİL');

                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/homepage');
                  } else {
                    print('EDICT-DIGITAL: User: NULL NULL NULL AMK NULL');

                    signIn();
                  }
                },
              )
            ],
          );
        });
  }

  signIn() async {
    try {
      print('EDICT-DIGITAL: ' + 'signIn() async START');
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsOTP,
      );

      print('EDICT-DIGITAL: AuthCredential: ' + credential?.toString());

      final UserCredential user = await _auth.signInWithCredential(credential);
      print('EDICT-DIGITAL: UserCredential: ' + user?.toString());
      final User currentUser = _auth.currentUser;
      print('EDICT-DIGITAL: CurrentUser: ' + currentUser?.toString());
      assert(user.user.uid == currentUser.uid);
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed('/homepage');
    } catch (e) {
      // handleError(e);
      print(e.toString());
    }
  }

  handleError(PlatformException error) {
    print(error);
    switch (error.code) {
      case 'ERROR_INVALID_VERIFICATION_CODE':
        FocusScope.of(context).requestFocus(new FocusNode());
        setState(() {
          errorMessage = 'Invalid Code';
        });
        Navigator.of(context).pop();
        smsOTPDialog(context).then((value) {
          print('sign in');
        });
        break;
      default:
        setState(() {
          errorMessage = error.message;
        });

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                decoration: InputDecoration(hintText: 'Enter Phone Number Eg. +910000000000'),
                onChanged: (value) {
                  this.phoneNo = value;
                },
              ),
            ),
            (errorMessage != ''
                ? Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  )
                : Container()),
            SizedBox(
              height: 10,
            ),
            RaisedButton(
              onPressed: () {
                verifyPhone();
              },
              child: Text('Verify'),
              textColor: Colors.white,
              elevation: 7,
              color: Colors.blue,
            )
          ],
        ),
      ),
    );
  }
}
