import 'package:sylvest_flutter/services/mangers.dart';
import 'package:sylvest_flutter/home/pages.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter/material.dart';

class TransferRequestsPage extends StatefulWidget {
  const TransferRequestsPage({Key? key, required this.verificationRights})
      : super(key: key);

  State<TransferRequestsPage> createState() => TransferRequestsPageState();
  final int verificationRights;
}

class TransferRequestsPageState extends State<TransferRequestsPage>
    implements LoadableListState {
  final manager = TransferManager();

  final List<GlobalKey<TransferRequestState>> _keys = [];

  List<TransferRequest> items = [];
  bool loading = false;
  bool refreshing = false;

  bool _verifying = false;

  final materialColor = const Color(0xFF733CE6);

  void _onDismiss(int id) {
    setState(() {
      items.removeWhere((element) => element.data.id == id);
    });
  }

  Future<void> _autoVerify() async {
    setState(() {
      _verifying = true;
    });
    for (int i = 0; i < widget.verificationRights && i < items.length; i++) {
      final key = _keys[i];
      await key.currentState!.accept(false);
    }
    setState(() {
      _verifying = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      refresh();
    });
  }

  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(children: [
        if (items.isNotEmpty)
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                  primary: materialColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  fixedSize: Size(double.maxFinite, 30)),
              onPressed: _verifying ? null : _autoVerify,
              child: Text("Verify ${widget.verificationRights} transactions")),
        if (items.isEmpty)
          Center(
            child: Text(
              "Unverified transfers will be presented here",
              style: TextStyle(color: Colors.black45, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ...items
      ]),
    );
  }

  @override
  Future<void> loadMore() async {
    if (loading || !manager.next()) return;
    setState(() {
      loading = true;
    });
    final transfers = await (manager as TransferManager).getTransfers(
        context, _onDismiss, _keys, widget.verificationRights, refresh);
    setState(() {
      items = transfers;
      loading = false;
    });
  }

  @override
  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
    });
    manager.reset();
    final transfers = await (manager as TransferManager).getTransfers(
        context, _onDismiss, _keys, widget.verificationRights, refresh);
    setState(() {
      items = transfers;
      refreshing = false;
    });
  }
}

class TransferRequestData {
  final String fromAddress, toAddress, amount;
  final int verificationsNumber;
  final bool isVerified;
  final int id;

  TransferRequestData(
      {required this.fromAddress,
      required this.toAddress,
      required this.amount,
      required this.isVerified,
      required this.id,
      required this.verificationsNumber});

  factory TransferRequestData.fromJson(Map json) => TransferRequestData(
      fromAddress: json["from_addr"],
      toAddress: json["to_addr"],
      amount: json["amount"],
      id: json["id"],
      isVerified: json["is_verified"],
      verificationsNumber: json["verified_num"]);
}

class TransferRequest extends StatefulWidget {
  const TransferRequest(
      {Key? key,
      required this.data,
      required this.onDismiss,
      required this.verificationRight,
      required this.refresh})
      : super(key: key);
  final TransferRequestData data;
  final void Function(int id) onDismiss;
  final void Function() refresh;
  final int verificationRight;

  @override
  State<TransferRequest> createState() => TransferRequestState();
}

class TransferRequestState extends State<TransferRequest> {
  final _materialColor = const Color(0xFF733CE6);
  final _manager = TransferManager();

  bool _accepting = false;
  late bool _accepted = widget.data.isVerified;

  Future<void> accept(bool refresh) async {
    setState(() {
      _accepting = true;
    });
    final transfer = await _manager.verifyTransfer(context, widget.data.id,
        widget.onDismiss, widget.verificationRight, widget.refresh);
    if (transfer.data.isVerified) {
      setState(() {
        _accepted = true;
      });
      await Future.delayed(Duration(seconds: 1));
      widget.onDismiss(transfer.data.id);
    }
    setState(() {
      _accepting = false;
    });
    if (refresh)
      widget.refresh();
  }

  Widget _button() {
    return InkWell(
      onTap: _accepting || widget.verificationRight <= 0
          ? null
          : () async => accept(true),
      child: Container(
        decoration: BoxDecoration(
            color: _accepting || widget.verificationRight <= 0
                ? Colors.grey.shade300
                : _materialColor,
            shape: BoxShape.circle),
        padding: const EdgeInsets.all(10),
        child: _accepting
            ? CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              )
            : Icon(LineIcons.check, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        onDismissed: (direction) => widget.onDismiss(widget.data.id),
        key: UniqueKey(),
        child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, spreadRadius: 2, blurRadius: 5)
                ]),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: _accepted
                ? SizedBox(
                    width: double.maxFinite,
                    child: Icon(
                      LineIcons.check,
                      color: _materialColor,
                    ),
                  )
                : Row(
                    children: [
                      _button(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TRAttribute(
                                title: "from: ",
                                attribute: widget.data.fromAddress),
                            TRAttribute(
                                title: "to: ",
                                attribute: widget.data.toAddress),
                            TRAttribute(
                                title: "amount: ",
                                attribute: widget.data.amount)
                          ],
                        ),
                      ),
                    ],
                  )));
  }
}

class TRAttribute extends StatelessWidget {
  const TRAttribute({Key? key, required this.title, required this.attribute})
      : super(key: key);

  final String title;
  final String attribute;

  String _attribute() {
    if (attribute.length < 13) return attribute;
    return attribute.substring(0, 5) +
        "..." +
        attribute.substring(attribute.length - 6);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        Text(_attribute(), style: TextStyle(color: Colors.black54))
      ],
    );
  }
}
