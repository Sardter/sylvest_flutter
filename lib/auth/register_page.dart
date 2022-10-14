import 'package:flutter/material.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  RegisterState createState() => RegisterState();
}

class RegisterState extends State<RegisterPage> {
  final _backgroundColor = Colors.white;
  final _materialColor = const Color(0xFF733CE6);

  bool _loading = false;

  String username = "", password = "", password2 = "", email = "";
  final TextEditingController usernameIn = TextEditingController(),
      passwordIn = TextEditingController(),
      passwordIn2 = TextEditingController(),
      emailIn = TextEditingController();

  double getSmallDiameter(BuildContext context) =>
      MediaQuery.of(context).size.width * 2 / 3;
  double getBiglDiameter(BuildContext context) =>
      MediaQuery.of(context).size.width * 7 / 8;

  void onSubmit() async {
    setState(() {
      _loading = true;
    });
    username = usernameIn.text;
    password = passwordIn.text;
    password2 = passwordIn2.text;
    email = emailIn.text;
    

    final response = await API()
        .getRegisterResponse(context, username, email, password, password2);
    setState(() {
      _loading = false;
    });
    if (response == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('A verification link has been sent to your account. '
              'Verify your account to login')));
      Navigator.pop(context);
    }
  }

  String? emailError, usernameError, pass1Error, pass2Error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        centerTitle: true,
        title: Text('Register',
            style: TextStyle(
              color: _materialColor,
              fontFamily: 'Quicksand',
            )),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.keyboard_arrow_left,
            color: _materialColor,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            right: -getSmallDiameter(context) / 3,
            top: -getSmallDiameter(context) / 3,
            child: Container(
              width: getSmallDiameter(context),
              height: getSmallDiameter(context),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Color.fromARGB(255, 119, 73, 218),
                    Color.fromARGB(255, 135, 96, 221)
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
          ),
          Positioned(
            left: -getBiglDiameter(context) / 4,
            top: -getBiglDiameter(context) / 4,
            child: Container(
              child: const Center(
                child: Text(
                  "sylvest",
                  style: TextStyle(
                      fontFamily: "Quicksand",
                      fontSize: 40,
                      color: Colors.white),
                ),
              ),
              width: getBiglDiameter(context),
              height: getBiglDiameter(context),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Color(0xFF733CE6),
                    Color.fromARGB(255, 135, 96, 221)
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
          ),
          Positioned(
            right: -getBiglDiameter(context) / 2,
            bottom: -getBiglDiameter(context) / 2,
            child: Container(
              width: getBiglDiameter(context),
              height: getBiglDiameter(context),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFF3E9EE)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ListView(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      //border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.fromLTRB(20, 300, 20, 10),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: emailIn,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              emailError = "Email can't be empty";
                            });
                            return;
                          }
                          bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%"
                                  "&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(value);
                          print(emailValid);

                          if (!emailValid) {
                            setState(() {
                              emailError = "Enter a valid email address";
                            });
                          } else {
                            setState(() {
                              emailError = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                            errorText: emailError,
                            focusedErrorBorder: InputBorder.none,
                            icon: Icon(
                              Icons.mail,
                              color: Color(0xFF733CE6),
                            ),
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            labelText: "Emails",
                            enabledBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      TextFormField(
                        controller: usernameIn,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              usernameError = "Username can't be empty";
                            });
                          } else {
                            setState(() {
                              usernameError = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                            errorText: usernameError,
                            focusedErrorBorder: InputBorder.none,
                            icon: Icon(
                              Icons.person,
                              color: Color(0xFF733CE6),
                            ),
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            labelText: "Username",
                            enabledBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      TextFormField(
                        controller: passwordIn,
                        obscureText: true,
                        onChanged: (value) {
                          if (value.length < 8) {
                            setState(() {
                              pass1Error = "Password must be longer than 8"
                                  " characters.";
                            });
                          } else {
                            setState(() {
                              pass1Error = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                            icon: Icon(
                              Icons.vpn_key,
                              color: Color(0xFF733CE6),
                            ),
                            errorText: pass1Error,
                            focusedErrorBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            labelText: "Password",
                            enabledBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      TextFormField(
                        controller: passwordIn2,
                        obscureText: true,
                        onChanged: (value) {
                          if (value != passwordIn.text) {
                            setState(() {
                              pass2Error = "Passwords must match!";
                            });
                          } else {
                            setState(() {
                              pass2Error = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                            icon: Icon(
                              Icons.vpn_key,
                              color: Color(0xFF733CE6),
                            ),
                            errorText: pass2Error,
                            errorBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            labelText: "Confirm Password",
                            enabledBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.grey)),
                      )
                    ],
                  ),
                ),
                /* Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 20, 10),
                        child: const Text(
                          "FORGOT PASSWORD?",
                          style:
                              TextStyle(color: Color(0xFF733CE6), fontSize: 11),
                        ))), */
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.89,
                        height: 40,
                        child: Container(
                          child: Material(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              //splashColor: Color.fromARGB(255, 179, 164, 212),
                              onTap: _loading ? null : () {
                                onSubmit();
                              },
                              child: Center(
                                child: _loading ? LoadingIndicator(size: 20,) : Text(
                                  "SIGN UP",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF733CE6),
                                    Color.fromARGB(255, 135, 96, 221)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter)),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "ALREADY HAVE AN ACCOUNT ? ",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          " SIGN IN",
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF733CE6),
                              fontWeight: FontWeight.w700),
                        ))
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
