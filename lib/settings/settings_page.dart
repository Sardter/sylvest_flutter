import 'package:flutter/material.dart';
import 'package:sylvest_flutter/services/api.dart';

class SettingsPage extends StatelessWidget {
  final void Function(int page) setPage;

  const SettingsPage({required this.setPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
          physics:
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: <Widget>[
            SettingOption(
                title: 'Logout',
                iconData: Icons.logout,
                onTap: () async {
                  await API().getLogoutResponse();
                  Navigator.pop(context);
                  setPage(0);
                })
          ],
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon:
                Icon(Icons.keyboard_arrow_left, color: const Color(0xFF733CE6)),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text('Settings',
              style: TextStyle(
                color: const Color(0xFF733CE6),
                fontFamily: 'Quicksand',
              )),
        ));
  }
}

class SettingOption extends StatelessWidget {
  const SettingOption(
      {Key? key,
      required this.title,
      required this.iconData,
      required this.onTap})
      : super(key: key);
  final String title;
  final IconData iconData;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
            ]),
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: IntrinsicHeight(
          child: Row(
            children: [
              const SizedBox(
                width: 10,
              ),
              Icon(iconData, color: const Color(0xFF733CE6)),
              const VerticalDivider(
                width: 30,
              ),
              Text(
                title,
                style: TextStyle(fontSize: 18),
              )
            ],
          ),
        ),
      ),
    );
  }
}
