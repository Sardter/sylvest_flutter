import 'package:flutter/material.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/api.dart';

class ForgotPasswordPage extends StatefulWidget {
  final Color backgroundColor, matterialColor, secondaryColor;
  final void Function(int page) setPage;

  const ForgotPasswordPage(
      this.backgroundColor, this.matterialColor, this.secondaryColor,
      {required this.setPage});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState(
      this.backgroundColor, this.matterialColor, this.secondaryColor);
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final Color backgroundColor, matterialColor, secondaryColor;
  ForgotPasswordPageState(
      this.backgroundColor, this.matterialColor, this.secondaryColor);

  final _emailController = TextEditingController();

  bool _loading = false;

  void _onSubmit(context) async {
    setState(() {
      _loading = true;
    });
    final response = await API().forgotPassword(context, _emailController.text);
    setState(() {
      _loading = false;
    });
    if (response['detail'] == "Password reset e-mail has been sent.") {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("An email with the reset link has been send")));
    } else
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Something went wrong")));
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
        title: Text('Forgot Password',
            style: TextStyle(
              color: matterialColor,
              fontFamily: 'Quicksand',
            )),
        leading: IconButton(
          onPressed: () {
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
                        controller: _emailController,
                        decoration: const InputDecoration(
                            icon: Icon(
                              Icons.email,
                              color: Color(0xFF733CE6),
                            ),
                            focusedBorder: InputBorder.none,
                            labelText: "Email",
                            enabledBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.grey)),
                      )
                    ],
                  ),
                ),
                Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 20, 10),
                          child: const Text(
                            "Already have an account?",
                            style:
                            TextStyle(color: Color(0xFF733CE6), fontSize: 11),
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
                                  "RESET PASSWORD",
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
