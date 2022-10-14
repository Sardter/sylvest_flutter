import 'package:flutter/material.dart';

class Username extends StatelessWidget {
  final String userid;
  final Color color;

  const Username({Key? key, required this.userid, required this.color})
      : super(key: key);

  @override
  Widget build(context) {
    return Row(
      children: [
        const SizedBox(
          width: 30,
        ),
        Text(userid,
            textAlign: TextAlign.start,
            style: TextStyle(color: color, fontSize: 12))
      ],
    );
  }
}
