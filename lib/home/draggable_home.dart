library draggable_home;

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class DraggableHome extends StatefulWidget {
  @override
  _DraggableHomeState createState() => _DraggableHomeState();

  /// Leading: A widget to display before the toolbar's title.
  final Widget? leading;

  /// Title: A Widget to display title in AppBar
  final Widget title;

  /// Center Title: Allows toggling of title from the center. By default title is in the center.
  final bool centerTitle;

  /// Action: A list of Widgets to display in a row after the title widget.
  final List<Widget>? actions;

  /// Always Show Leading And Action : This make Leading and Action always visible. Default value is false.
  final bool alwaysShowLeadingAndAction;

  /// Drawer: Drawers are typically used with the Scaffold.drawer property.
  final Widget? drawer;

  /// Header Expanded Height : Height of the header widget. The height is a double between 0.0 and 1.0. The default value of height is 0.35 and should be less than stretchMaxHeight
  final double headerExpandedHeight;

  /// Header Widget: A widget to display Header above body.
  final Widget headerWidget;

  /// headerBottomBar: AppBar or toolBar like widget just above the body.

  final Widget? headerBottomBar;

  /// backgroundColor: The color of the Material widget that underlies the entire DraggableHome body.
  final Color? backgroundColor;

  /// curvedBodyRadius: Creates a border top left and top right radius of body, Default radius of the body is 20.0. For no radius simply set value to 0.
  final double curvedBodyRadius;

  /// body: A widget to Body
  final List<Widget> body;

  /// fullyStretchable: Allows toggling of fully expand draggability of the DraggableHome. Set this to true to allow the user to fully expand the header.
  final bool fullyStretchable;

  /// stretchTriggerOffset: The offset of overscroll required to fully expand the header.
  final double stretchTriggerOffset;

  /// expandedBody: A widget to display when fully expanded as header or expandedBody above body.
  final Widget? expandedBody;

  /// stretchMaxHeight: Height of the expandedBody widget. The height is a double between 0.0 and 0.95. The default value of height is 0.9 and should be greater than headerExpandedHeight
  final double stretchMaxHeight;

  /// floatingActionButton: An object that defines a position for the FloatingActionButton based on the Scaffold's ScaffoldPreLayoutGeometry.
  final Widget? floatingActionButton;

  /// bottomSheet: A persistent bottom sheet shows information that supplements the primary content of the app. A persistent bottom sheet remains visible even when the user interacts with other parts of the app.
  final Widget? bottomSheet;

  /// bottomNavigationBarHeight: This is requires when using custom height to adjust body height. This make no effect on bottomNavigationBar.
  final double? bottomNavigationBarHeight;

  /// bottomNavigationBar: Snack bars slide from underneath the bottom navigation bar while bottom sheets are stacked on top.
  final Widget? bottomNavigationBar;

  /// floatingActionButtonLocation: An object that defines a position for the FloatingActionButton based on the Scaffold's ScaffoldPreLayoutGeometry.

  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// floatingActionButtonAnimator: Provider of animations to move the FloatingActionButton between FloatingActionButtonLocations.
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  final Function() onRefresh, onLoad;

  /// This will create DraggableHome.
  const DraggableHome(
      {Key? key,
      this.leading,
      required this.title,
      this.centerTitle = true,
      this.actions,
      this.alwaysShowLeadingAndAction = false,
      this.headerExpandedHeight = 0.35,
      required this.headerWidget,
      this.headerBottomBar,
      this.backgroundColor,
      this.curvedBodyRadius = 20,
      required this.body,
      this.drawer,
      this.fullyStretchable = false,
      this.stretchTriggerOffset = 200,
      this.expandedBody,
      this.stretchMaxHeight = 0.9,
      this.bottomSheet,
      this.bottomNavigationBarHeight = kBottomNavigationBarHeight,
      this.bottomNavigationBar,
      this.floatingActionButton,
      this.floatingActionButtonLocation,
      this.floatingActionButtonAnimator,
      required this.onLoad,
      required this.onRefresh})
      : assert(headerExpandedHeight > 0.0 &&
            headerExpandedHeight < stretchMaxHeight),
        assert(
          (stretchMaxHeight > headerExpandedHeight) && (stretchMaxHeight < .95),
        ),
        super(key: key);
}

class _DraggableHomeState extends State<DraggableHome> {
  final BehaviorSubject<bool> isFullyExpanded =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> isFullyCollapsed =
      BehaviorSubject<bool>.seeded(false);

  @override
  void dispose() {
    isFullyExpanded.close();
    isFullyCollapsed.close();
    super.dispose();
  }

  bool _willRefresh = true;
  void _onRefresh() {
    print("refreshing");
    if (_willRefresh) {
      widget.onRefresh();
      _willRefresh = false;
      Future.delayed(Duration(seconds: 2), () {
        _willRefresh = true;
      });
    }
  }

  bool _willLoad = true;
  void _onLoad() {
    if (_willLoad) {
      widget.onLoad();
      print("loading");
      _willLoad = false;
      Future.delayed(Duration(seconds: 2), () {
        _willLoad = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight =
        AppBar().preferredSize.height + widget.curvedBodyRadius;

    final double topPadding = MediaQuery.of(context).padding.top;

    final double expandedHeight =
        MediaQuery.of(context).size.height * widget.headerExpandedHeight;

    final double fullyExpandedHeight =
        MediaQuery.of(context).size.height * (widget.stretchMaxHeight);

    return Scaffold(
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      drawer: widget.drawer,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            // isFullyCollapsed
            if ((isFullyExpanded.value) &&
                notification.metrics.extentBefore > 100) {
              isFullyExpanded.add(false);
            }
            //isFullyCollapsed
            if (notification.metrics.extentBefore >
                expandedHeight - AppBar().preferredSize.height - 40) {
              if (!(isFullyCollapsed.value)) isFullyCollapsed.add(true);
            } else {
              if ((isFullyCollapsed.value)) isFullyCollapsed.add(false);
            }
          }
          if (notification.metrics.pixels <
              notification.metrics.minScrollExtent - 50) {
            _onRefresh();
          } else if (notification.metrics.pixels >
              notification.metrics.maxScrollExtent + 10) {
            _onLoad();
          }
          return false;
        },
        child: sliver(context, appBarHeight, fullyExpandedHeight,
            expandedHeight, topPadding),
      ),
      bottomSheet: widget.bottomSheet,
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      floatingActionButtonAnimator: widget.floatingActionButtonAnimator,
    );
  }

  CustomScrollView sliver(
    BuildContext context,
    double appBarHeight,
    double fullyExpandedHeight,
    double expandedHeight,
    double topPadding,
  ) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        StreamBuilder<List<bool>>(
          stream: CombineLatestStream.list<bool>(
              [isFullyCollapsed.stream, isFullyExpanded.stream]),
          builder: (BuildContext context, AsyncSnapshot<List<bool>> snapshot) {
            List<bool> streams = (snapshot.data ?? [false, false]);

            return SliverAppBar(
              leading: widget.alwaysShowLeadingAndAction
                  ? widget.leading
                  : !streams[0]
                      ? SizedBox()
                      : widget.leading,
              actions: widget.alwaysShowLeadingAndAction
                  ? widget.actions
                  : !streams[0]
                      ? []
                      : widget.actions,
              elevation: 0,
              pinned: true,
              stretch: true,
              centerTitle: widget.centerTitle,
              title: StreamBuilder<bool>(
                stream: null,
                builder: (context, snapshot) {
                  return AnimatedOpacity(
                    opacity: streams[0] ? 1 : 0,
                    duration: Duration(milliseconds: 100),
                    child: widget.title,
                  );
                },
              ),
              collapsedHeight: appBarHeight,
              expandedHeight: streams[1] ? fullyExpandedHeight : expandedHeight,
              flexibleSpace: Stack(
                children: [
                  FlexibleSpaceBar(
                    background: Container(
                        child: streams[1]
                            ? (widget.expandedBody == null
                                ? Container()
                                : widget.expandedBody)
                            : widget.headerWidget),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: roundedCorner(context),
                  ),
                  Positioned(
                    bottom: 4 + widget.curvedBodyRadius,
                    child: AnimatedContainer(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      curve: Curves.easeInOutCirc,
                      duration: Duration(milliseconds: 100),
                      height: streams[0]
                          ? 0
                          : streams[1]
                              ? 0
                              : kToolbarHeight,
                      width: MediaQuery.of(context).size.width,
                      child: streams[0]
                          ? SizedBox()
                          : streams[1]
                              ? SizedBox()
                              : widget.headerBottomBar ?? Container(),
                    ),
                  )
                ],
              ),
              stretchTriggerOffset: widget.stretchTriggerOffset,
              onStretchTrigger: widget.fullyStretchable
                  ? () async {
                      if (streams[1] == false) {
                        isFullyExpanded.add(true);
                      }
                    }
                  : null,
            );
          },
        ),
        sliverList(context, appBarHeight),
      ],
    );
  }

  Container roundedCorner(BuildContext context) {
    return Container(
        //transform: Matrix4.translationValues(0, -1, 0),
        alignment: Alignment.center,
        //height: widget.curvedBodyRadius,s
        decoration: BoxDecoration(
          color: const Color(0xFFad8ef0),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(widget.curvedBodyRadius),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Icon(
            Icons.drag_handle,
            color: Colors.white,
          ),
        ));
  }

  SliverList sliverList(BuildContext context, double topHeight) {
    final double bottomPadding =
        widget.bottomNavigationBar == null ? 0 : kBottomNavigationBarHeight;
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                    color: widget.backgroundColor ??
                        Theme.of(context).scaffoldBackgroundColor,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30))),
                height: MediaQuery.of(context).size.height -
                    topHeight -
                    bottomPadding,
              ),
              Column(
                children: [
                  //expandedUpArrow(),
                  //Body
                  ...widget.body
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  StreamBuilder<bool> expandedUpArrow() {
    return StreamBuilder<bool>(
        stream: isFullyExpanded.stream,
        builder: (context, snapshot) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 500),
            height: (snapshot.data ?? false) ? 25 : 0,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Icon(
                Icons.drag_handle,
                color: (snapshot.data ?? false) ? null : Colors.transparent,
              ),
            ),
          );
        });
  }
}
