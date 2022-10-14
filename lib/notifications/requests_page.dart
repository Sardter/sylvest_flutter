import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';

import '../services/image_service.dart';

class RequestsWidget extends StatelessWidget {
  const RequestsWidget({Key? key, required this.requestNum}) : super(key: key);
  final int requestNum;
  final Color materialColor = const Color(0xFF733CE6);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => showMaterialModalBottomSheet(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          context: context,
          builder: (context) => RequestsPage()),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              LineIcons.userPlus,
              color: materialColor,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              "Requests",
              style: TextStyle(color: materialColor),
            ),
            SizedBox(
              width: 10,
            ),
            Badge(
              badgeColor: const Color(0xFF733CE6),
              badgeContent: Text(requestNum.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  )),
            ),
            Spacer(),
            Icon(
              LineIcons.angleRight,
              color: materialColor,
            )
          ],
        ),
      ),
    );
  }
}

class FollowRequest extends StatefulWidget {
  const FollowRequest({Key? key, required this.userData}) : super(key: key);
  final UserData userData;

  @override
  State<FollowRequest> createState() => _FollowRequestState();
}

class _FollowRequestState extends State<FollowRequest> {
  bool _loading = false;
  String? _actionState;

  Widget _loadingWidget(bool accept) {
    return SizedBox(
      width: 25,
      height: 25,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: accept ? Colors.white : const Color(0xFF733CE6),
      ),
    );
  }

  Future<void> _onAccept() async {
    setState(() {
      _loading = true;
    });
    await API().acceptFollow(widget.userData.id, context);
    setState(() {
      _loading = false;
      _actionState = "Accepted";
    });
  }

  Future<void> _onDecline() async {
    setState(() {
      _loading = true;
    });
    await API().declineFollow(widget.userData.id, context);
    setState(() {
      _loading = false;
      _actionState = "Declined";
    });
  }

  Widget _acceptButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      splashColor: Colors.white,
      onTap: _loading ? null : _onAccept,
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF733CE6),
          shape: BoxShape.circle,
        ),
        child: _loading
            ? _loadingWidget(true)
            : Icon(
                LineIcons.check,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _declineButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: _loading ? null : _onDecline,
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF733CE6).withOpacity(0.5)),
          shape: BoxShape.circle,
        ),
        child: _loading
            ? _loadingWidget(false)
            : Icon(
                LineIcons.times,
                color: const Color(0xFF733CE6),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return UserPage(widget.userData.id);
        }));
      },
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            SylvestImageProvider(
              url: widget.userData.profileImage),
            const SizedBox(
              width: 10,
            ),
            Text(widget.userData.username),
            Spacer(),
            if (_actionState != null)
              Text(_actionState!, style: TextStyle(color: Colors.black26)),
            if (_actionState == null) _acceptButton(),
            if (_actionState == null) _declineButton()
          ],
        ),
      ),
    );
  }
}

class RequestsPage extends StatefulWidget {
  @override
  State<RequestsPage> createState() => RequestsPageState();
}

class RequestsPageState extends State<RequestsPage> {
  List<FollowRequest> _requests = [];
  bool _loading = false;

  Future<void> _getRequests() async {
    setState(() {
      _loading = true;
    });
    final newRequests = await API().getFollowRequests(context);

    setState(() {
      _requests = newRequests;
      _loading = false;
    });
    print(_requests);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getRequests();
    });
    super.initState();
  }

  Widget _refreshingWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 30,
      width: 30,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.black26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      controller: ModalScrollController.of(context),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
                Text(
                  "Requests",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                  ),
                ),
                if (_loading) _refreshingWidget()
              ] +
              _requests,
        ),
      ),
    );
  }
}
