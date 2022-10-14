import 'package:any_link_preview/any_link_preview.dart';
import 'package:better_player/better_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/services/mangers.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../forms/form_responses.dart';
import '../../forms/forms.dart';
import '../../home/main_components.dart';
import '../../modals/modals.dart';
import '../../services/api.dart';
import '../../services/image_service.dart';
import '../post_util.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar(this.title, this.target, this.current, this.currency,
      this.textColor, this.backgroundColor,
      {Key? key})
      : super(key: key);
  final String title, currency;
  final double target, current;
  final Color textColor, backgroundColor;

  @override
  Widget build(BuildContext context) {
    double progress = current / target;
    return Container(
        constraints: const BoxConstraints(minHeight: 93),
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black12,
                    value: progress,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  RichText(
                    text: TextSpan(
                        style: TextStyle(color: textColor),
                        children: <TextSpan>[
                          TextSpan(
                              text: current.toInt().toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w400)),
                          TextSpan(
                              text: ' $currency',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                  fontFamily: 'Quicksand')),
                          const TextSpan(
                            text: " of ",
                          ),
                          TextSpan(
                              text: target.toInt().toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w400)),
                          TextSpan(
                              text: ' $currency',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                  fontFamily: 'Quicksand')),
                        ]),
                  ),
                ])));
  }
}

class Contributors extends StatefulWidget {
  Contributors(
      {required this.title,
      required this.backgroundColor,
      required this.textColor,
      required this.activatedColor,
      required this.buttonText,
      required this.isContributing,
      required this.formData,
      required this.amountAvailible,
      required this.userData,
      required this.postId,
      required this.isAuthor,
      required this.address,
      required this.target,
      required this.fundedSoFar,
      required this.minimumAmountToFund,
      required this.canContribute,
      required this.postType});
  final String title, buttonText;
  final bool canContribute;
  final UserData? userData;
  final String? address;
  final Color backgroundColor, textColor, activatedColor;
  final PostType postType;
  final bool isContributing, isAuthor;
  final int postId;
  final List? formData;
  final double? target, fundedSoFar, minimumAmountToFund, amountAvailible;

  @override
  State<Contributors> createState() => ContributorsState();
}

class ContributorsState extends State<Contributors> {
  List<UserData> _contributors = [];
  bool _loading = false;
  late bool _isContributing = widget.isContributing;

  late final _manger = UserManager(
      type: widget.postType == PostType.Project
          ? UserManagerType.Contributors
          : UserManagerType.Attendees);

  Future<void> _getContributors() async {
    setState(() {
      _loading = true;
    });
    final contributors = await _manger.getUser(context, widget.postId);
    if (mounted)
      setState(() {
        _contributors = contributors;
        _loading = false;
      });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getContributors();
    });
    super.initState();
  }

  void _contribute() {
    setState(() {
      if (_isContributing) {
        _contributors
            .removeWhere((element) => element.id == widget.userData!.id);
        _isContributing = false;
      } else {
        _contributors.add(widget.userData!);
        _isContributing = true;
      }
    });
  }

  void _onContributorsTap() {
    launchModal(
        context,
        UserListModal(
          title: widget.title,
          id: widget.postId,
          type: widget.postType == PostType.Project
              ? UserManagerType.Contributors
              : UserManagerType.Attendees,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.title,
                style: TextStyle(
                    color: widget.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 10),
            if (_contributors.isNotEmpty && !_loading)
              GestureDetector(
                onTap: () => _onContributorsTap(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 35),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _contributors
                        .map<Widget>(
                          (contributor) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: SylvestImageProvider(
                              radius: 17.5,
                              url: contributor.profileImage,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
            else if (_loading)
              SizedBox(height: 35, child: LoadingIndicator())
            else
              SizedBox(
                height: 35,
                child: Center(
                  child: Text(
                    'No one yet!',
                    style: TextStyle(color: widget.textColor.withOpacity(0.5)),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (widget.canContribute && widget.isAuthor)
              ResponsesButton(
                color: widget.backgroundColor,
                postId: widget.postId,
              )
            else if (widget.canContribute)
              ContributeButton(
                  target: widget.target,
                  fundedSoFar: widget.fundedSoFar,
                  minimumAmountToFund: widget.minimumAmountToFund,
                  formData: widget.formData,
                  activatedColor: widget.activatedColor,
                  backgroundColor: widget.backgroundColor,
                  address: widget.address,
                  amountAvailible: widget.amountAvailible,
                  buttonText: widget.buttonText,
                  isContributing: _isContributing,
                  contribute: () => _contribute(),
                  pk: widget.postId)
          ],
        ),
      ),
    );
  }
}

class ResponsesButton extends StatelessWidget {
  const ResponsesButton({Key? key, required this.color, required this.postId})
      : super(key: key);
  final Color color;
  final int postId;

  _onTap(context) {
    launchModal(
        context,
        FormResponsesModal(
          postId: postId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            minimumSize: Size(double.maxFinite, 40),
            primary: color,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30))),
        onPressed: () => _onTap(context),
        child: Text("Responses"));
  }
}

class Paragraphs extends StatelessWidget {
  const Paragraphs(this.text, this.textColor, {Key? key}) : super(key: key);
  final String text;
  final Color textColor;

  // TODO: make texts raw somehow (probably in the builder)
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: TextStyle(color: textColor),
      ),
    );
  }
}

class Images extends StatefulWidget {
  Images({Key? key, required this.images}) : super(key: key);
  final List images;

  @override
  State<Images> createState() => ImagesState();
}

class ImagesState extends State<Images> {
  int _current = 0;
  bool _indicatorVisible = true;
  final _controller = CarouselController();

  Widget _indicator() {
    int count = 0;
    return Container(
      decoration: BoxDecoration(
          /* color: Colors.white60, */ borderRadius: BorderRadius.circular(30)),
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
              SizedBox(
                width: 1,
              )
            ] +
            widget.images.map<Widget>((e) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                    color: count++ == _current ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(100)),
                height: 5,
                width: 5,
              );
            }).toList() +
            [
              SizedBox(
                width: 1,
              )
            ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _indicatorVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CarouselSlider(
            carouselController: _controller,
            items: widget.images
                .map<Widget>((image) => Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.only(top: 10.0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: SylvestImage(
                          url: image['image'],
                          useDefault: false,
                        ),
                      ),
                    ))
                .toList(),
            options: CarouselOptions(
                height: 330,
                aspectRatio: 1,
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  setState(() {
                    _indicatorVisible = true;
                    _current = index;
                  });

                  Future.delayed(Duration(seconds: 3), () {
                    setState(() {
                      _indicatorVisible = false;
                    });
                  });
                },
                enableInfiniteScroll: false)),
        if (_indicatorVisible)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _indicator(),
            ),
            bottom: 10,
          ),
        if (_indicatorVisible)
          Positioned(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => _controller.previousPage(),
                    icon: Icon(Icons.keyboard_arrow_left),
                    iconSize: 30,
                    color: Colors.white60,
                  ))),
        if (_indicatorVisible)
          Positioned(
              child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => _controller.nextPage(),
                    icon: Icon(Icons.keyboard_arrow_right),
                    iconSize: 30,
                    color: Colors.white60,
                  ))),
      ],
    );
  }
}

class ContributeButton extends StatefulWidget {
  ContributeButton(
      {required this.activatedColor,
      required this.backgroundColor,
      required this.buttonText,
      required this.isContributing,
      required this.contribute,
      required this.formData,
      required this.pk,
      required this.target,
      required this.address,
      required this.fundedSoFar,
      required this.amountAvailible,
      required this.minimumAmountToFund});

  final String buttonText;
  final Color backgroundColor, activatedColor;
  final int pk;
  final List? formData;
  final String? address;
  final double? target, fundedSoFar, minimumAmountToFund, amountAvailible;
  final void Function() contribute;
  bool isContributing;

  @override
  State<ContributeButton> createState() => ContributeButtonState();
}

class ContributeButtonState extends State<ContributeButton> {
  Color? color;
  Color textColor = Colors.white;
  double elevation = 2;
  late String text = widget.buttonText;

  void _contribute(context) async {
    if (widget.isContributing) {
      setState(() {
        widget.isContributing = false;
      });
    } else {
      if (widget.formData != null) {
        final response = await showDialog(
            context: context,
            builder: (context) {
              return ContributionForm.fromJson(
                widget.formData!,
                fundedSoFar: widget.fundedSoFar,
                target: widget.target,
                amoundAvailble: widget.amountAvailible,
                minimumAmountToFund: widget.minimumAmountToFund,
                pk: widget.pk,
                address: widget.address,
              );
            });
        if (response == null || !response) return;
      }
    }
    if (widget.buttonText != 'Attend') {
      final response = await API().contribute(widget.pk, context);
      print(response);
      if (response['contributed'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['data']),
          backgroundColor: Colors.red,
        ));
        return;
      }
    } else {
      final response = await API().attend(widget.pk, context);
      if (response['attended'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['data']),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }
    if (!widget.isContributing)
      setState(() {
        print("contributing");
        widget.isContributing = true;
      });
    widget.contribute();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                elevation: widget.isContributing ? 0 : 2,
                primary: widget.isContributing
                    ? widget.activatedColor
                    : widget.backgroundColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              _contribute(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isContributing) ... const [
                  Icon(LineIcons.check, color: Colors.white),
                  SizedBox(width: 10)
                ],
                Text(text,
                    style: TextStyle(
                        color: widget.isContributing
                            ? Colors.white54
                            : Colors.white))
              ],
            )));
  }
}

class Link extends StatelessWidget {
  const Link(
      {Key? key,
      required this.link,
      required this.backgroundColor,
      required this.materialColor})
      : super(key: key);
  final String link;
  final Color backgroundColor, materialColor;

  // String _urlMaker(String url) {
  //   String result = url;
  //   if (!url.contains('https://') && !url.contains('http://')) {
  //     result = 'https://' + url;
  //   }
  //   return result;
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AnyLinkPreview(
        link: link,
        displayDirection: UIDirection.uiDirectionHorizontal,
        boxShadow: [
          BoxShadow(color: Colors.black12, spreadRadius: 2, blurRadius: 5)
        ],
        placeholderWidget: SizedBox(
          height: 100,
          child: LoadingIndicator(),
        ),
        errorWidget: SizedBox(
          height: 100,
          width: double.maxFinite,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(LineIcons.exclamation, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Url failed to load",
                style: TextStyle(color: Colors.red),
              )
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        titleStyle:
            TextStyle(color: materialColor, fontWeight: FontWeight.bold),
        bodyStyle: TextStyle(
          color: materialColor.withOpacity(0.7),
        ),
      ),
    );
  }
}

class Video extends StatefulWidget {
  final String url;
  const Video({Key? key, required this.url}) : super(key: key);

  @override
  State<Video> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  BetterPlayerController? controller;
  bool canChange = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (controller != null) controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return VisibilityDetector(
      key: widget.key!,
      onVisibilityChanged: (info) async {
        if (!mounted || !canChange) return;

        print("visibility ${info.visibleFraction * 100}");
        if (info.visibleFraction == 1) {
          setState(() {
            if (controller == null) canChange = false;
            Future.delayed(Duration(seconds: 5), () {
              setState(() {
                canChange = true;
              });
            });
            controller = BetterPlayerController(
                BetterPlayerConfiguration(
                  looping: true,
                  aspectRatio: 1,
                  fit: BoxFit.cover,
                  controlsConfiguration: BetterPlayerControlsConfiguration(
                      playerTheme: BetterPlayerTheme.cupertino,
                      enableFullscreen: false,
                      enableQualities: false,
                      enableAudioTracks: false,
                      enableOverflowMenu: false,
                      showControlsOnInitialize: true,
                      controlBarColor: const Color(0xFF733CE6).withOpacity(0.8),
                      playIcon: LineIcons.play,
                      enablePip: false,
                      enableSkips: false,
                      controlsHideTime: Duration(milliseconds: 50),
                      enableSubtitles: false,
                      enablePlaybackSpeed: false),
                ),
                betterPlayerDataSource: BetterPlayerDataSource.network(
                    widget.url,
                    cacheConfiguration:
                        BetterPlayerCacheConfiguration(useCache: true)));
          });
        } else {
          setState(() {
            if (controller == null) return;
            canChange = false;
            Future.delayed(Duration(seconds: 5), () {
              setState(() {
                canChange = true;
              });
            });
            controller = null;
          });
        }
      },
      child: Container(
          child: controller == null
              ? SizedBox(
                  height: 300,
                  child: LoadingIndicator(),
                )
              : BetterPlayer(
                  controller: controller!,
                )),
    );
  }
}
