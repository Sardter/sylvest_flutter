import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:web3dart/web3dart.dart';

import '../services/image_service.dart';

class TransferService {
  final double currentBalance;

  const TransferService({required this.currentBalance});

  void _displayMessage(
      String errorMessage, BuildContext context, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorMessage),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  bool validateAmount(String amount, BuildContext context,
      [void Function(String error)? displayError]) {
    if (amount.isEmpty) {
      if (displayError == null)
        _displayMessage("Amount field cannot be empty!", context, false);
      else displayError("Amount field cannot be empty!");
      return false;
    }
    double res;
    try {
      res = double.parse(amount);
    } catch (e) {
      if (displayError == null)
        _displayMessage("A valid integer should be specified!", context, false);
      else displayError("A valid integer should be specified!");
      return false;
    }
    if (res == 0) {
      _displayMessage("Transfer amount cannot be zero!", context, false);
      return false;
    }
    if (res > currentBalance) {
      if (displayError == null)
        _displayMessage(
            "Transfer amount ($res) cannot exceed current balance ($currentBalance)!", context, false);
      else displayError("Transfer amount cannot exceed current balance!");
      return false;
    }
    return true;
  }

  bool validateAddress(String address, BuildContext context) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      _displayMessage("Address is not valid", context, false);
      return false;
    }
  }

  double? _getAmount(String str, BuildContext context ,
      [void Function(String error)? displayError ]) {
    final amount = double.tryParse(str);
    if (!validateAmount(str, context, displayError)) return null;
    return amount! * pow(10, 18);
  }

  Future<void> onSendToUser(
      int userId, String amountStr, BuildContext context ,
      [void Function(String error)? displayError]) async {
    final amount = _getAmount(amountStr, context, displayError);
    if (amount == null) return;

    final response = await API().sendTokenToUser(userId, amount, context);
    if (response.containsKey('error')) {
      _displayMessage(response['error'], context, false);
    } else {
      _displayMessage('Tokens sent successfully!', context, true);
    }
  }

  Future<void> onSendToAddress(
      String address, String amountStr, BuildContext context,
      [void Function(String error)? displayError]) async {
    final amount = _getAmount(amountStr, context, displayError);
    if (amount == null || !validateAddress(address, context)) return;
    final response = await API().sendTokenToAddress(address, amount, context);
    if (response.containsKey('error')) {
      _displayMessage(response['error'], context, false);
    } else {
      _displayMessage('Tokens sent successfully!', context, true);
    }
  }

  Future<void> transferToUserDialog(
      UserData userData, String address, context) async {
    await showDialog(
        context: context,
        builder: (context) => TransferToUserDialog(
              userData: userData,
              address: address,
              service: this,
            ));
  }
}

class TransferToUserDialog extends StatefulWidget {
  const TransferToUserDialog(
      {Key? key,
      required this.userData,
      required this.address,
      required this.service})
      : super(key: key);
  final UserData userData;
  final String address;
  final TransferService service;

  @override
  State<TransferToUserDialog> createState() => _TransferToUserDialogState();
}

class _TransferToUserDialogState extends State<TransferToUserDialog> {
  final _textController = TextEditingController();

  bool _sending = false;
  String? _errorText;

  Future<void> _onSend() async {
    setState(() {
      _sending = true;
    });
    await widget.service
        .onSendToUser(widget.userData.id, _textController.text, context);
    setState(() {
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text.rich(TextSpan(
                        style: TextStyle(fontSize: 20, fontFamily: 'Quicksand'),
                        children: [
                          TextSpan(
                            text: "Transfer to ",
                          ),
                          TextSpan(
                            text: widget.userData.username,
                            style: TextStyle(
                                color: const Color.fromARGB(255, 130, 89, 218)),
                          ),
                        ])),
                    const SizedBox(
                      height: 10,
                    ),
                    SylvestImageProvider(
                      radius: 40,
                      url: widget.userData.profileImage,),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        onChanged: (value) => setState(() {
                          widget.service.validateAmount(value, context, (error) {
                            setState(() {
                              _errorText = error;
                            });
                          });
                        }),
                        decoration: InputDecoration(
                            hintText: "Amount",
                            isCollapsed: true,
                            isDense: true,
                            errorText: _errorText,
                            border: InputBorder.none),
                        controller: _textController,
                      ),
                    ),
                    if (_textController.text.isNotEmpty && _errorText == null)
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              fixedSize: Size(double.maxFinite, 30),
                              primary: Color.fromARGB(255, 130, 89, 218),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              )),
                          onPressed: _sending ? null : _onSend,
                          child: _sending
                              ? LoadingIndicator(size: 20)
                              : Text("Send"))
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
