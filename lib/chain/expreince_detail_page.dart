import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/chain/transfer_service.dart';
import 'package:sylvest_flutter/posts/post_util.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:sylvest_flutter/chain/transfers_page.dart';
import 'package:sylvest_flutter/services/pick_image_service.dart';

import '../services/image_service.dart';

enum ChainVerifiedState { None, Pending, Accepted, Denied }

Map<String, ChainVerifiedState> strToVerifiedState = {
  'N': ChainVerifiedState.None,
  'P': ChainVerifiedState.Pending,
  'A': ChainVerifiedState.Accepted,
  'D': ChainVerifiedState.Denied
};

class ExpreincePageData {
  final int id, level, currentXP, targetXP;
  int? verificationRights;
  String? balance;
  int stakedLevel;
  String? address;
  final bool isConnected;
  final ChainVerifiedState verifiedState;

  ExpreincePageData(
      {required this.id,
      required this.verificationRights,
      required this.address,
      required this.balance,
      required this.currentXP,
      required this.isConnected,
      required this.level,
      required this.verifiedState,
      required this.stakedLevel,
      required this.targetXP});

  factory ExpreincePageData.fromJson(Map json) {
    print(json);
    return ExpreincePageData(
        id: json['id'],
        isConnected: json['chain_attributes']['connected'],
        verificationRights: json['verifications'],
        address: json['wallet_address'],
        balance: json['chain_attributes']['balance'],
        currentXP: json['current_xp'],
        level: json['level'],
        stakedLevel: json['staked_level'],
        verifiedState: strToVerifiedState[json['verified_state']]!,
        targetXP: json['target_xp']);
  }
}

class ExprienceDetailPage extends StatefulWidget {
  final void Function(int page) setPage;

  const ExprienceDetailPage({Key? key, required this.setPage}) : super(key: key);

  State<ExprienceDetailPage> createState() => _ExprienceDetailPageState();
}

class _ExprienceDetailPageState extends State<ExprienceDetailPage> {
  final materialColor = const Color(0xFF733CE6);
  final backgroundColor = Colors.white;
  ExpreincePageData? _data;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onRefresh();
    });
  }

  void _onRefresh() async {
    if (!_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });
      final newData = await API().getChainPage(context, widget.setPage);
      if (mounted)
        setState(() {
          _data = newData;
          _isRefreshing = false;
        });
    }
  }

  Widget _refreshingWidget() {
    return Positioned(
        top: 100,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: EdgeInsets.all(5),
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color.fromARGB(255, 154, 121, 226),
          ),
        ));
  }

  Widget _notConnected() {
    return Center(
      child: Column(
        children: [
          Icon(LineIcons.exclamation, color: materialColor, size: 50),
          const SizedBox(height: 10),
          Text(
            "There was a problem when connecting to the SYLK newtwork!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          )
        ],
      ),
    );
  }

  Widget _sliver() {
    return FutureBuilder<ExpreincePageData?>(
      future: API().getChainPage(context, widget.setPage),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: LoadingIndicator(),
          );
        }
        final data = snapshot.data!;

        return CustomScrollView(
          physics:
              AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              snap: true,
              floating: true,
              pinned: true,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_left),
                color: materialColor,
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: backgroundColor,
              actions: [],
            ),
            SliverList(
                delegate: SliverChildListDelegate(data.isConnected
                    ? [
                        CircularExpreinceBar(
                            data.currentXP, data.targetXP, data.level),
                        PointsIndicator(data.verificationRights),
                        if (data.verifiedState ==
                            ChainVerifiedState.Accepted) ...[
                          WalletAddress(walletAddress: data.address!),
                          CoinIndicator(
                              data.balance != null ? data.balance! : null),
                          ChainButtons(),
                          if (data.balance != null)
                            ChainActions(
                                balance: double.parse(data.balance!),
                                onRefresh: _onRefresh,
                                verificationRights: data.verificationRights!)
                        ] else
                          GenerateAddress(
                            onGenerate: _onRefresh,
                            verifiedState: data.verifiedState,
                          )
                      ]
                    : [_notConnected()]))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton:
            _data == null || _data!.level - _data!.stakedLevel == 0
                ? null
                : FloatingActionButton.extended(
                    backgroundColor: Colors.white,
                    icon: Icon(
                      Icons.add_box,
                      color: materialColor,
                    ),
                    onPressed: () async {
                      stake() async {
                        final staked = await API().stakeLevels(context);
                        if (staked != null) {
                          setState(() {
                            _data!.stakedLevel = staked;
                          });
                        }
                      }

                      await stake();
                    },
                    label: Text(
                      "Stake ${_data!.level - _data!.stakedLevel} Levels",
                      style: TextStyle(color: materialColor),
                    )),
        body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels <
                  notification.metrics.minScrollExtent - 50) {
                _onRefresh();
              }
              return false;
            },
            child: Stack(
              alignment: Alignment.center,
              children: [_sliver(), if (_isRefreshing) _refreshingWidget()],
            )));
  }
}

class ChainButtons extends StatefulWidget {
  const ChainButtons({Key? key}) : super(key: key);

  @override
  State<ChainButtons> createState() => _ChainButtonsState();
}

class _ChainButtonsState extends State<ChainButtons> {
  final materialColor = const Color(0xFF733CE6);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: materialColor,
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  onPressed: () {},
                  child: const Text("Verify Transfers"))),
        ],
      ),
    );
  }
}

class ChainActions extends StatelessWidget {
  final double balance;
  final int verificationRights;
  final void Function() onRefresh;

  const ChainActions(
      {Key? key,
      required this.balance,
      required this.verificationRights,
      required this.onRefresh})
      : super(key: key);

  @override
  Widget build(context) {
    return Container(
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            ChainAction(
                "Transfer",
                Transfer(
                  balance,
                  onRefresh: onRefresh,
                )),
            ChainAction(
                "Retrieve",
                Retreive(
                  onRefresh: onRefresh,
                )),
            ChainAction(
                "Verify",
                TransferRequestsPage(
                  verificationRights: verificationRights,
                ))
          ],
        ));
  }
}

class ChainAction extends StatelessWidget {
  final String title;
  final Widget action;
  final materialColor = const Color(0xFF733CE6);

  const ChainAction(this.title, this.action);

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 2)
          ]),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ExpandablePanel(
          controller: ExpandableController(initialExpanded: true),
          theme: ExpandableThemeData(
              hasIcon: false,
              headerAlignment: ExpandablePanelHeaderAlignment.center),
          header: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: materialColor,
                    fontFamily: 'Quicksand',
                    fontSize: 20),
              ),
              Divider(
                height: 0,
                endIndent: 100,
                indent: 100,
              )
            ],
          ),
          collapsed: Text(""),
          expanded: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(5),
            child: action,
          )),
    );
  }
}

class Transfer extends StatefulWidget {


  final double balance;
  final void Function() onRefresh;
  Transfer(this.balance, {required this.onRefresh});

  @override
  State<Transfer> createState() => TransferState();
}

class TransferState extends State<Transfer> {
  final materialColor = const Color(0xFF733CE6);
  final addressController = TextEditingController(),
      amountController = TextEditingController();

  late final transferService = TransferService(currentBalance: widget.balance);

  bool _sending = false;

  Future<void> _onTransfer() async {
    final amount = amountController.text;
    final address = addressController.text;

    setState(() {
      _sending = true;
    });
    await transferService.onSendToAddress(address, amount, context);
    setState(() {
      _sending = false;
    });
  }


  @override
  Widget build(context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              controller: addressController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: "Address"),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              controller: amountController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: "Amount"),
            ),
          ),
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.maxFinite, 35),
                  primary: materialColor,
                  side: BorderSide(color: materialColor.withOpacity(0.7)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              onPressed:
                  _sending ||
                  amountController.text.isEmpty || addressController.text.isEmpty
                  ? null
                  : () async {
                await _onTransfer();
              },
              child:
              _sending ? Text("Request sent") : const Text("Send SYLK"))
        ],
      ),
    );
  }
}

class TransfarableUsers extends StatefulWidget {
  const TransfarableUsers(
      {Key? key, required this.users, required this.setAddress})
      : super(key: key);
  final List users;
  final void Function(int address) setAddress;

  @override
  State<TransfarableUsers> createState() => _TransfarableUsersState();
}

class _TransfarableUsersState extends State<TransfarableUsers> {
  int _selectedUser = -1;

  Widget _user(String username, String? imageUrl, String? address, int id,
      int index, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedUser == index) {
            _selectedUser = -1;
          } else
            _selectedUser = index;
          widget.setAddress(id);
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: _selectedUser == index
                    ? Border.all(color: const Color(0xFF733CE6))
                    : null),
            child: SylvestImageProvider(
             url: imageUrl,),
          ),
          Text(username, style: TextStyle(fontSize: 12))
        ],
      ),
    );
  }

  List<Widget> _users() {
    int _count = 0;
    return widget.users.map<Widget>((user) {
      final result = _user(user['username'], user['image'], user['address'],
          user['id'], _count, _count == _selectedUser);
      _count++;
      return result;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final users = _users();
    return Container(
      constraints: BoxConstraints(maxHeight: 61),
      child: users.isNotEmpty
          ? ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: users,
            )
          : Center(
              child: Text(
                'No users to transfer',
                style: TextStyle(color: Colors.black45),
              ),
            ),
    );
  }
}

class Retreive extends StatefulWidget {
  const Retreive({Key? key, required this.onRefresh}) : super(key: key);
  final void Function() onRefresh;

  @override
  State<Retreive> createState() => RetreiveState();
}

class RetreiveState extends State<Retreive> {
  int _sum(List<double> amounts) {
    double sum = 0;
    amounts.forEach((element) {
      sum += element - (element / 10);
    });
    return sum.toInt();
  }

  bool _retrieving = false;

  Widget _retrieveFromAllButton(List<RetreivablePost> posts, context) {
    final sum =
        _sum(posts.map<double>((e) => e.data.projectFields!.current).toList());
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: OutlinedButton(
        onPressed: sum > 0 && !_retrieving
            ? () async {
                setState(() {
                  _retrieving = true;
                });
                for (var i = 0; i < posts.length; i++) {
                  final post = posts[i];
                  if (post.data.projectFields!.current > 0) {
                    await post.retrieve(context);
                  }
                }
                widget.onRefresh();
                setState(() {
                  _retrieving = false;
                });
              }
            : null,
        child: Text(_retrieving ? "Retrieving..." : "Retrieve from all: $sum"),
        style: OutlinedButton.styleFrom(
            primary: const Color(0xFF733CE6),
            minimumSize: Size(double.maxFinite, 35),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
      child: FutureBuilder<List<RetreivablePost>>(
        future: API().getRetrievableProjects(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LoadingIndicator();
          }
          final data = snapshot.data!;
          final posts = data.map<RetreivablePost>((e) {
            e.onRefresh = widget.onRefresh;
            return e;
          }).toList();
          return data.isNotEmpty
              ? Column(
                  children: posts.cast<Widget>() +
                      <Widget>[_retrieveFromAllButton(posts, context)],
                )
              : SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(
                      "No project to retrieve from!",
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                );
        },
      ),
    );
  }
}

class RetreivablePost extends StatefulWidget {
  RetreivablePost({
    Key? key,
    required this.data,
    required this.onRefresh,
  }) : super(key: key);
  final MasterPostData data;
  void Function()? onRefresh;

  factory RetreivablePost.fromJson(Map json) {
    return RetreivablePost(
      data: MasterPostData.fromJson(json),
      onRefresh: null,
    );
  }

  @override
  State<RetreivablePost> createState() => _RetreivablePostState();

  Future<Map> retrieve(context) {
    return API().retrieveFromProject(context, data.postId);
  }
}

class _RetreivablePostState extends State<RetreivablePost> {
  late double _totalFunded = widget.data.projectFields!.totalFunded;
  bool _retrieving = false;

  Widget _authorInfo() {
    return Row(
      children: [
        SylvestImageProvider(
          url: widget.data.authorDetails.profileImage,),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.data.authorDetails.username,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            _title()
          ],
        )),
        //_postAttributes()
      ],
    );
  }

  Widget _title() {
    return Text(
      widget.data.title,
      style: TextStyle(fontSize: 20, color: Colors.white),
    );
  }

  Widget _retrieveButton() {
    return Column(
      children: [
        ElevatedButton(
            onPressed:
                widget.data.projectFields!.current.toInt() == 0 || _retrieving
                    ? null
                    : () => onRetrieve(),
            style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 128, 80, 230),
                shape: CircleBorder()
                //minimumSize: Size(double.maxFinite, 35)
                ),
            child: _retrieving
                ? CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : Icon(
                    Icons.check,
                    color: Colors.white,
                  )),
        Text(
          "Retrieve \n ${(widget.data.projectFields!.current - (widget.data.projectFields!.current / 10)).toInt()}",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 10),
        )
      ],
    );
  }

  Widget _progressIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _totalFunded / widget.data.projectFields!.target,
          color: Colors.white,
          backgroundColor: Colors.black12,
        ),
        const SizedBox(
          height: 5,
        ),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: '${_totalFunded.toInt()} ',
              style: TextStyle(color: Colors.white, fontFamily: '')),
          TextSpan(
              text: 'SYLK of ',
              style: TextStyle(
                  color: Colors.white, fontFamily: 'Quicksand', fontSize: 12)),
          TextSpan(
              text: '${widget.data.projectFields!.target.toInt()} ',
              style: TextStyle(color: Colors.white, fontFamily: '')),
          TextSpan(
              text: 'SYLK',
              style: TextStyle(
                  color: Colors.white, fontFamily: 'Quicksand', fontSize: 12)),
        ]))
      ],
    );
  }

  void onRetrieve() async {
    setState(() {
      _retrieving = true;
    });
    await widget.retrieve(context);
    setState(() {
      _retrieving = false;
    });
    widget.onRefresh!();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PostDetailPage(widget.data.postId))),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
            ],
            gradient: LinearGradient(colors: [
              const Color(0xFF733CE6),
              Color.fromARGB(255, 149, 114, 223)
            ]),
            color: const Color(0xFF733CE6)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _authorInfo(),
                  const SizedBox(
                    height: 10,
                  ),
                  _progressIndicator(),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
            _retrieveButton(),
          ],
        ),
      ),
    );
  }
}

class PointsIndicator extends StatelessWidget {
  final int? verifications;
  final materialColor = const Color(0xFF733CE6);
  const PointsIndicator(this.verifications);

  @override
  Widget build(context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Center(
        child: Text(
            verifications != null
                ? '$verifications Verification Rights'
                : 'Generate a wallet address to get points!',
            style: TextStyle(color: materialColor, fontFamily: 'Quicksand')),
      ),
    );
  }
}

class CircularExpreinceBar extends StatefulWidget {
  final int current, target, level;

  const CircularExpreinceBar(this.current, this.target, this.level);

  @override
  State<CircularExpreinceBar> createState() => _CircularExpreinceBarState();
}

class _CircularExpreinceBarState extends State<CircularExpreinceBar> {
  final materialColor = const Color(0xFF733CE6);

  @override
  Widget build(context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 300,
            height: 300,
            child: CircularProgressIndicator(
              value: widget.current / widget.target,
              color: materialColor,
              backgroundColor: materialColor.withOpacity(0.2),
              strokeWidth: 2,
            ),
          ),
          Column(
            children: [
              Text(widget.level.toString(),
                  style: TextStyle(
                      color: materialColor,
                      fontSize: 100,
                      fontFamily: '',
                      fontWeight: FontWeight.w100)),
              Text("${widget.current} / ${widget.target}",
                  style: TextStyle(
                      color: materialColor.withOpacity(0.7),
                      fontFamily: 'Quicksand',
                      fontSize: 15,
                      fontWeight: FontWeight.w200))
            ],
          ),
        ],
      ),
    );
  }
}

class CoinIndicator extends StatelessWidget {
  final materialColor = const Color(0xFF733CE6);
  final formatter = NumberFormat(',000.000000');
  double? balance;

  CoinIndicator(String? balance) {
    if (balance != null) this.balance = double.parse(balance);
  }

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [materialColor, materialColor.withOpacity(0.65)]),
          borderRadius: BorderRadius.circular(30)),
      margin: EdgeInsets.only(left: 15, right: 15, bottom: 15),
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Icon(
            LineIcons.wallet,
            color: Colors.white60,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
              child: Text(
            balance != null ? formatter.format(balance) : 'No balance',
            style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontFamily: '',
                fontWeight: FontWeight.w100),
          ))
        ],
      ),
    );
  }
}

class WalletAddress extends StatelessWidget {
  const WalletAddress({Key? key, required this.walletAddress})
      : super(key: key);
  final String walletAddress;
  final materialColor = const Color(0xFF733CE6);

  @override
  Widget build(BuildContext context) {
    final address = walletAddress.substring(0, 5) +
        "..." +
        walletAddress.substring(
            walletAddress.length - 6, walletAddress.length - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          address,
          style: TextStyle(
              color: materialColor,
              fontSize: 20,
              fontFamily: '',
              fontWeight: FontWeight.w200),
        ),
        IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: walletAddress));
            },
            icon: Icon(
              Icons.copy,
              size: 20,
              color: materialColor,
            ))
      ],
    );
  }
}

class KYCVerificationWidget extends StatefulWidget {
  const KYCVerificationWidget({Key? key, required this.refresh})
      : super(key: key);
  final void Function() refresh;

  @override
  State<KYCVerificationWidget> createState() => _KYCVerificationWidgetState();
}

class _KYCVerificationWidgetState extends State<KYCVerificationWidget> {
  final _materialColor = const Color(0xFF733CE6);
  final _imageService = ImageService();
  final _warningController = KYCWarningsController();

  XFile? _frontPage, _backPage;

  Widget _fileWidget(XFile file, bool isFront) {
    String name() {
      if (file.name.length < 15) return file.name;
      return file.name.substring(0, 13) + "...";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            LineIcons.imageFile,
            color: _materialColor,
          ),
          const SizedBox(width: 10),
          Text(
            isFront ? "Front Page: " + name() : "Back Page: " + name(),
            style:
                TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              if (isFront) {
                _frontPage = null;
              } else {
                _backPage = null;
              }
            }),
            child: const Icon(LineIcons.times),
          )
        ],
      ),
    );
  }

  TextStyle _kycImportantStyle() {
    return TextStyle(color: _materialColor, fontFamily: 'Quicksand');
  }

  TextStyle _kycTextStyle() {
    return TextStyle(color: Colors.black87);
  }

  // Future<bool> _validateProfile(context) async {
  //   final api = API();
  //   bool valid = true;
  //   final profile = (await api.getProfile(context, (page) {}, false))!.data;
  //   if (profile.firstName.isEmpty) {
  //     _warningController.onAdd!("First Name cannot be empty");
  //     valid = false;
  //   }
  //   if (profile.lastName.isEmpty) {
  //     _warningController.onAdd!("Last Name cannot be empty");
  //     valid = false;
  //   }
  //   if (profile.gender == null || profile.gender!.isEmpty) {
  //     _warningController.onAdd!("Gender cannot be empty");
  //     valid = false;
  //   }
  //   if (profile.address == null || profile.address!.isEmpty) {
  //     _warningController.onAdd!("Address cannot be empty");
  //     valid = false;
  //   }
  //   return valid;
  // }

  Future<void> _onGenerate(context) async {
    //if (!await _validateProfile(context)) return;
    //final frontImage = base64Encode(File(_frontPage!.path).readAsBytesSync());
    //final backImage = base64Encode(File(_backPage!.path).readAsBytesSync());
    await API().verifyChainPage(context, "", "");
    Navigator.pop(context);
    widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("KYC Verification",
                      style: TextStyle(
                          fontSize: 20,
                          color: _materialColor,
                          fontFamily: 'Quicksand')),
                  const SizedBox(
                    height: 10,
                  ),
                  RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: "To generate a wallet, you will need to upload a "
                                "clear photo of an ",
                            style: _kycTextStyle()),
                        TextSpan(
                            text: "identification licence", style: _kycImportantStyle()),
                        TextSpan(
                            text: " such as the government "
                                "issued id, passport or a driver licence. Moreover, ",
                            style: _kycTextStyle()),
                        TextSpan(
                            text: "gender, address, name and surname",
                            style: _kycImportantStyle()),
                        TextSpan(
                            text: " fields must be filled accurately in the ",
                            style: _kycTextStyle()),
                        TextSpan(
                            text: "profile edit section", style: _kycImportantStyle()),
                        TextSpan(
                            text: ". Only after, you will be able to "
                                "gain the rewards. This is only done to ensure that "
                                "rewards gained are fair and no foul play is conducted.",
                            style: _kycTextStyle())
                      ])),
                  if (_frontPage != null) _fileWidget(_frontPage!, true),
                  if (_backPage != null) _fileWidget(_backPage!, false),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          style: TextButton.styleFrom(primary: _materialColor),
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel")),
                      if (_frontPage == null)
                        TextButton(
                            style: TextButton.styleFrom(primary: _materialColor),
                            onPressed: () async {
                              final selectedImage =
                              await _imageService.getImage(context);
                              setState(() {
                                _frontPage = selectedImage;
                              });
                            },
                            child: Text("Upload ID front")),
                      if (_backPage == null)
                        TextButton(
                            style: TextButton.styleFrom(primary: _materialColor),
                            onPressed: () async {
                              final selectedImage =
                              await _imageService.getImage(context);
                              setState(() {
                                _backPage = selectedImage;
                              });
                            },
                            child: Text("Upload ID back")),
                      if (_backPage != null && _frontPage != null)
                        TextButton(
                            style: TextButton.styleFrom(primary: _materialColor),
                            onPressed: () async => await _onGenerate(context),
                            child: Text("Verify")),
                    ],
                  )
                ],
              ),
            ),
          ),
          Positioned.fill(child: KYCWarnings(controller: _warningController))
        ],
      ),
    );
  }
}

class GenerateAddress extends StatelessWidget {
  final materialColor = const Color(0xFF733CE6);
  final void Function() onGenerate;
  final ChainVerifiedState verifiedState;

  const GenerateAddress(
      {Key? key, required this.onGenerate, required this.verifiedState})
      : super(key: key);

  Future<void> _onGenerate(context) async {
    //if (!await _validateProfile(context)) return;
    //final frontImage = base64Encode(File(_frontPage!.path).readAsBytesSync());
    //final backImage = base64Encode(File(_backPage!.path).readAsBytesSync());
    await API().verifyChainPage(context, "", "");
    //Navigator.pop(context);
    onGenerate();
  }

  Future<void> _launchDialog(context) async {
    // await showDialog(
    //   context: context,
    //   builder: (context) => KYCVerificationWidget(refresh: onGenerate),
    // );
    await _onGenerate(context);
  }

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () async {
        await _launchDialog(context);
      },
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 2)
        ], color: Colors.white, borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(left: 15, right: 15, bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: SizedBox(
          height: 50,
          child: Center(
              child: Text(
            verifiedState != ChainVerifiedState.Pending
                ? 'Generate Wallet!'
                : "Actions will be available after verification",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: materialColor,
                fontSize: 20,
                fontFamily: '',
                fontWeight: FontWeight.w200),
          )),
        ),
      ),
    );
  }
}

class KYCWarning extends StatelessWidget {
  const KYCWarning(
      {Key? key,
        required this.id,
        required this.errorMessage,
        required this.onDismissed})
      : super(key: key);
  final int id;
  final String errorMessage;
  final void Function(int id) onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: UniqueKey(),
        onDismissed: (direction) => onDismissed(id),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          margin: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(LineIcons.exclamationCircle, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(errorMessage,
                      style: TextStyle(color: Colors.white))),
              Spacer(),
              IconButton(
                  onPressed: () => onDismissed(id),
                  icon: Icon(LineIcons.times, color: Colors.white54))
            ],
          ),
        ));
  }
}

class KYCWarningsController {
  List<KYCWarning> warnings = [];
  void Function(String errorMessage)? onAdd;
}

class KYCWarnings extends StatefulWidget {
  const KYCWarnings({Key? key, required this.controller}) : super(key: key);
  final KYCWarningsController controller;

  @override
  State<KYCWarnings> createState() => _KYCWarningsState();
}

class _KYCWarningsState extends State<KYCWarnings> {
  int _id = 0;

  @override
  void initState() {
    widget.controller.onAdd = _onAdd;
    super.initState();
  }

  void _onAdd(String errorMessage) {
    setState(() {
      widget.controller.warnings.add(KYCWarning(
          id: _id++, errorMessage: errorMessage, onDismissed: _onDismissed));
    });
  }

  void _onDismissed(int id) {
    setState(() {
      widget.controller.warnings.removeWhere((element) => element.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: widget.controller.warnings,
      ),
    );
  }
}
