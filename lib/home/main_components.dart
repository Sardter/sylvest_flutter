import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/services/api.dart';
import 'package:sylvest_flutter/chain/expreince_detail_page.dart';

import '../services/image_service.dart';

class LevelDrawer extends StatelessWidget {
  final Color matterialCollor;
  final void Function(int page) setPage;
  const LevelDrawer(this.matterialCollor, this.setPage);

  Widget _notConnected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LineIcons.exclamation, color: Colors.white, size: 50),
          const SizedBox(height: 10),
          Text(
            "There was a problem when connecting to the SYLK newtwork!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(30))),
        backgroundColor: matterialCollor,
        child: FutureBuilder<ExpreincePageData?>(
          future: API().getChainPage(context, setPage),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox(
                width: 50,
                height: 50,
                child: Center(
                  child: LoadingIndicator(),
                ),
              );
            }
            final data = snapshot.data!;
            if (!data.isConnected) {
              return _notConnected();
            }
            final chainActions = data.address == null
                ? [
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 30),
                                primary: Colors.white,
                                //onPrimary: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20))),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ExprienceDetailPage(
                                          setPage: setPage,
                                        ))),
                            child: const Text(
                              "Generate Address",
                              style: TextStyle(color: const Color(0xFF733CE6)),
                            ))),
                  ]
                : [
                    Expanded(
                        child: ChainDrawerOptions(options: [
                      ChainDrawerOption(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ExprienceDetailPage(
                                        setPage: setPage,
                                      ))),
                          title: "Transfer"),
                      ChainDrawerOption(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ExprienceDetailPage(
                                        setPage: setPage,
                                      ))),
                          title: "Retrieve"),
                    ])),
                    ChainDrawerButtons(
                      tokenAmount: data.balance!,
                    )
                  ];
            return Column(
              children: <Widget>[
                    const SizedBox(
                      height: 70,
                    ),
                    LevelIndicator(
                      level: data.level,
                      currentXP: data.currentXP,
                      targerXP: data.targetXP,
                      setPage: setPage,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text("${data.currentXP} / ${data.targetXP}",
                        style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Quicksand',
                            fontSize: 20,
                            fontWeight: FontWeight.w200)),
                    const SizedBox(
                      height: 15,
                    ),
                  ] +
                  chainActions,
            );
          },
        ));
  }
}

class ChainDrawerOptions extends StatelessWidget {
  final List<ChainDrawerOption> options;

  const ChainDrawerOptions({required this.options});

  List<Widget> _withDividers() {
    final withDividers = <Widget>[];
    options.forEach((option) {
      withDividers.add(option);
      withDividers.add(const Divider(
        color: Colors.white10,
        height: 0,
      ));
    });
    return withDividers;
  }

  @override
  Widget build(context) {
    return Column(
      children: _withDividers(),
    );
  }
}

class ChainDrawerOption extends StatelessWidget {
  final String title;
  final void Function() onTap;

  const ChainDrawerOption({required this.onTap, required this.title});

  @override
  Widget build(context) {
    return ListTile(
      style: ListTileStyle.drawer,
      onTap: onTap,
      title: Text(title, style: TextStyle(color: Colors.white)),
      leading: Icon(LineIcons.angleRight, color: Colors.white70),
    );
  }
}

class ChainDrawerButtons extends StatelessWidget {
  final materialColor = const Color(0xFF733CE6);
  final String tokenAmount;

  const ChainDrawerButtons({required this.tokenAmount});

  String _shortner(String str) {
    if (str.length < 10) return str;
    return str.substring(0, 10) + "...";
  }

  @override
  Widget build(context) {
    return Column(
      children: [
        ListTile(
          style: ListTileStyle.drawer,
          title: Text("Sylvest Coins:  ${_shortner(tokenAmount)}",
              style: TextStyle(color: Colors.white, fontFamily: "Quicksand")),
          leading: const Icon(LineIcons.wallet, color: Colors.white70),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 30),
                    primary: Colors.white,
                    onPrimary: materialColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                onPressed: () => {},
                child: const Text("Deposit"))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 30),
                    primary: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                onPressed: () => {},
                child: const Text("Withdraw"))),
        const SizedBox(
          height: 10,
        )
      ],
    );
  }
}

class LevelIndicator extends StatelessWidget {
  final int level;
  final int currentXP;
  final int targerXP;
  final void Function(int page) setPage;

  const LevelIndicator(
      {Key? key,
      required this.level,
      required this.currentXP,
      required this.setPage,
      required this.targerXP})
      : super(key: key);

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ExprienceDetailPage(
                    setPage: setPage,
                  ))),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            height: 150,
            width: 150,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
              backgroundColor: Colors.black12,
              value: currentXP / targerXP,
            ),
          ),
          Positioned(
            child: Text(level.toString(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontFamily: '',
                    fontWeight: FontWeight.w100)),
          ),
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final double size;
  const LoadingIndicator({this.size = 50.0});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.grey.shade400,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class SmallProfileImage extends StatelessWidget {
  final String? imageData;
  final Color color;
  const SmallProfileImage(this.imageData, this.color);

  factory SmallProfileImage.fromJson(Map json, Color color) {
    return SmallProfileImage(json['image'], color);
  }

  @override
  Widget build(BuildContext context) {
    if (imageData == null) {
      return Icon(LineIcons.user, color: color);
    } else {
      return SylvestImageProvider(
        radius: 14,
        url: imageData,
      );
    }
  }
}

class LoadingDetailPage extends StatefulWidget {
  const LoadingDetailPage({Key? key}) : super(key: key);

  @override
  State<LoadingDetailPage> createState() => _LoadingDetailPageState();
}

class _LoadingDetailPageState extends State<LoadingDetailPage> {
  bool _show404 = false;

  void _showError() {
    Future.delayed(Duration(seconds: 30), () {
      setState(() {
        _show404 = true;
      });
    });
  }

  @override
  void initState() {
    _showError();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              LineIcons.angleLeft,
              color: const Color(0xFF733CE6),
            )),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingIndicator(),
          if (_show404) ...[
            SizedBox(height: 10),
            Text(
              "Page not found",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.grey.shade300),
            )
          ]
        ],
      ),
    );
  }
}
