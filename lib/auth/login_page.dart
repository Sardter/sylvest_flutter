import 'package:flutter/material.dart';
import 'package:sylvest_flutter/auth/password_reset.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/api.dart';

class LoginPage extends StatefulWidget {
  final Color backgroundColor, matterialColor, secondaryColor;
  final void Function(int page) setPage;
  final bool popAgain;

  const LoginPage(
      this.backgroundColor, this.matterialColor, this.secondaryColor,
      {required this.setPage, required this.popAgain});

  @override
  LoginPageState createState() => LoginPageState(
      this.backgroundColor, this.matterialColor, this.secondaryColor);
}

class LoginPageState extends State<LoginPage> {
  final Color backgroundColor, matterialColor, secondaryColor;
  LoginPageState(
      this.backgroundColor, this.matterialColor, this.secondaryColor);

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _loading = false;

  void _onSubmit(context) async {
    setState(() {
      _loading = true;
    });
    final response = await API().getLoginResponse(_usernameController.text,
        _emailController.text, _passwordController.text, context);
    setState(() {
      _loading = false;
    });
    if (response != null) Navigator.pop(context, response);
  }

  double getSmallDiameter(BuildContext context) =>
      MediaQuery.of(context).size.width * 2 / 3;
  double getBiglDiameter(BuildContext context) =>
      MediaQuery.of(context).size.width * 7 / 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        centerTitle: true,
        title: Text('Sign in',
            style: TextStyle(
              color: matterialColor,
              fontFamily: 'Quicksand',
            )),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
            if (widget.popAgain)
              Navigator.pop(context);
            widget.setPage(0);
          },
          icon: Icon(
            Icons.keyboard_arrow_left,
            color: matterialColor,
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
                        controller: _usernameController,
                        decoration: const InputDecoration(
                            icon: Icon(
                              Icons.person,
                              color: Color(0xFF733CE6),
                            ),
                            focusedBorder: InputBorder.none,
                            labelText: "Username",
                            enabledBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            icon: Icon(
                              Icons.vpn_key,
                              color: Color(0xFF733CE6),
                            ),
                            focusedBorder: InputBorder.none,
                            labelText: "Password",
                            enabledBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.grey)),
                      )
                    ],
                  ),
                ),
                Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordPage(
                                  backgroundColor,
                                  matterialColor,
                                  secondaryColor,
                                  setPage: widget.setPage))),
                      child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 20, 10),
                          child: const Text(
                            "FORGOT PASSWORD?",
                            style: TextStyle(
                                color: Color(0xFF733CE6), fontSize: 11),
                          )),
                    )),
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
                                _onSubmit(context);
                              },
                              child: Center(
                                child: _loading ? LoadingIndicator(size: 20,) : Text(
                                  "SIGN IN",
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
                      "DON'T HAVE AN ACCOUNT ? ",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          " SIGN UP",
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
