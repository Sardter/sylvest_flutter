import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/subjects/subject_util.dart';
import 'package:sylvest_flutter/subjects/user/user_page.dart';

import '../../services/image_service.dart';

class CommunityMembersModal extends StatefulWidget {
  const CommunityMembersModal(
      {Key? key, required this.communityId, required this.onRefresh})
      : super(key: key);
  final int communityId;
  final void Function() onRefresh;

  @override
  State<CommunityMembersModal> createState() => _CommunityMembersModalState();
}

class _CommunityMembersModalState extends State<CommunityMembersModal> {
  final _manager = RolledUserManager();

  bool _refreshing = false;
  bool _loading = false;
  List<RolledUser> _members = [];

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
    });
    final members =
        await _manager.getMembers(context, widget.communityId, false);
    if (mounted)
    setState(() {
      _members = members;
      _refreshing = false;
    });
  }

  Future<void> _load() async {
    if (!_loading && _manager.next()) {
      setState(() {
        _loading = true;
      });
      final members =
      await _manager.getMembers(context, widget.communityId, true);
      if (mounted)
        setState(() {
          _members += members;
          _members.sort();
          _loading = false;
        });
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _refresh();
    });
    super.initState();
  }

  Widget _roleDivider(Roll role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(role.toString().split(".").last,
            style: TextStyle(fontSize: 20, fontFamily: 'Quicksand')),
        const Divider()
      ],
    );
  }

  Widget _user(RolledUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SylvestImageProvider(
            url: user.profileImage,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(user.username,
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Text(
              strToCommunityRoll
                  .map((key, value) => MapEntry(value, key))[user.role]!,
              style: TextStyle(fontSize: 14, color: Colors.black45))
        ],
      ),
    );
  }

  Widget _userWithOptions(RolledUser user, int index) {
    final _controller = ExpandableController();
    return ExpandablePanel(
        theme: ExpandableThemeData(hasIcon: false),
        controller: _controller,
        header: _user(user),
        collapsed: SizedBox(),
        expanded: _options(user, index));
  }

  Widget _option(String action, void Function() onTap) {
    Map<String, IconData> _icons = {
      'Profile': Icons.person,
      'Change Role': Icons.change_circle,
      'Ban': Icons.block,
    };

    return InkWell(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(_icons[action], color: const Color(0xFF733CE6)),
            const SizedBox(width: 10),
            Text(action)
          ],
        ),
      ),
    );
  }

  Widget _options(RolledUser user, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Divider(),
          _option("Profile", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => UserPage(user.id)));
          }),
          if (user.allowedActions.contains(CommunityAction.Roles))
            _option("Change Role", () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return ChangeRoleWidget(
                      userId: user.id,
                      communityId: widget.communityId,
                      initialRole: user.role,
                      memberIndex: index,
                      refreshMembers: (updatedRole, memberIndex) =>
                          setState(() {
                        widget.onRefresh();
                        final curr = _members[memberIndex];
                        _members[memberIndex] = RolledUser(
                            id: curr.id,
                            username: curr.username,
                            allowedActions: curr.allowedActions,
                            role: updatedRole,
                            profileImage: curr.profileImage);
                      }),
                    );
                  });
            }),
          if (user.allowedActions.contains(CommunityAction.Ban))
            _option("Ban", () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Text("Are your sure you want to ban this user?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.black54),
                            )),
                        TextButton(
                            onPressed: () async {
                              await API().banFromCommunity(
                                  widget.communityId, user.id, context);
                              Navigator.pop(context);
                              widget.onRefresh();
                            },
                            child: Text(
                              "Ban",
                              style: TextStyle(color: const Color(0xFF733CE6)),
                            )),
                      ],
                    );
                  });
            }),
        ],
      ),
    );
  }

  List<Widget> _builder() {
    final _needsDivider = Roll.values.map((e) => true).toList();
    final result = <Widget>[];
    _members.sort();
    for (int i = 0; i < _members.length; i++) {
      final user = _members[i];
      for (int j = 0; j < _needsDivider.length; j++) {
        if (_needsDivider[j] && user.role == Roll.values[j]) {
          result.add(_roleDivider(user.role));
          _needsDivider[j] = false;
        }
      }
      result.add(_userWithOptions(user, i));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return _refreshing ? LoadingIndicator() : NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent) {
          _load();
        }
        return false;
      },
      child: ListView(
          padding: const EdgeInsets.all(10),
          physics:
          AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          controller: ModalScrollController.of(context),
          shrinkWrap: true,
          children: _builder()
      ),
    );
  }
}

class ChangeRoleWidget extends StatefulWidget {
  const ChangeRoleWidget(
      {Key? key,
      required this.initialRole,
      required this.userId,
      required this.communityId,
      required this.refreshMembers,
      required this.memberIndex})
      : super(key: key);
  final Roll initialRole;
  final int userId, memberIndex;
  final int communityId;
  final void Function(Roll updatedRole, int memberIndex) refreshMembers;

  @override
  State<ChangeRoleWidget> createState() => _ChangeRoleWidgetState();
}

class _ChangeRoleWidgetState extends State<ChangeRoleWidget> {
  late Roll _selectedRoll = widget.initialRole;

  Widget _role(Roll roll, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRoll = roll;
        });
      },
      child: Container(
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF733CE6) : Colors.white,
            borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
                child: Text(
                    strToCommunityRoll
                        .map((key, value) => MapEntry(value, key))[roll]!,
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black))),
            if (isSelected)
              Icon(
                Icons.check,
                color: Colors.white,
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      content: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children:
              [
                ...Roll.values
                    .where((element) =>
                        !const [Roll.NotMember, Roll.None].contains(element))
                    .map((e) => _role(e, e == _selectedRoll)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Cancel"),
                        style: TextButton.styleFrom(primary: Colors.black54)),
                    if (_selectedRoll != widget.initialRole)
                      TextButton(
                          onPressed: () async {
                            await API().changeCommunityRole(
                                widget.communityId,
                                widget.userId,
                                strToCommunityRoll
                                    .map((key, value) => MapEntry(value, key))[_selectedRoll]!.toLowerCase(),
                                context);
                            Navigator.pop(context);
                            widget.refreshMembers(_selectedRoll, widget.memberIndex);
                          },
                          child: Text("Ok"),
                          style: TextButton.styleFrom(
                              primary: const Color(0xFF733CE6))),
                  ],
                )
              ],
        ),
      ),
    );
  }
}
