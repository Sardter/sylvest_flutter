import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sylvest_flutter/post_builder/post_builder_building_blocks.dart';

class SampleBlock extends StatelessWidget {
  final void Function(BlockType type) onPressed;

  const SampleBlock({Key? key, required this.onPressed}) : super(key: key);

  BlockType get blockType => throw UnimplementedError();

  Widget content(IconData icon, Color color) {
    return InkWell(
      onTap: () => onPressed(blockType),
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          children: [
            CircleAvatar(
              child: Icon(icon, color: Colors.white),
              backgroundColor: color,
              radius: 30,
            ),
            const SizedBox(height: 10),
            Text(blockType.toShortString(), style: TextStyle(
              fontFamily: 'Quicksand'
            )),
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class SampleParagraph extends SampleBlock {
  const SampleParagraph({required void Function(BlockType type) onPressed})
      : super(onPressed: onPressed);

  @override
  BlockType get blockType => BlockType.paragraph;

  @override
  Widget build(BuildContext context) {
    return super.content(LineIcons.alignLeft, Colors.blue);
  }
}

class SampleImage extends SampleBlock {
  const SampleImage({required void Function(BlockType type) onPressed})
      : super(onPressed: onPressed);

  @override
  BlockType get blockType => BlockType.image;

  @override
  Widget build(BuildContext context) {
    return super.content(LineIcons.image, Colors.red);
  }
}

class SampleVideo extends SampleBlock {
  const SampleVideo({required void Function(BlockType type) onPressed})
      : super(onPressed: onPressed);

  @override
  BlockType get blockType => BlockType.video;

  @override
  Widget build(BuildContext context) {
    return super.content(LineIcons.video, Colors.green);
  }
}

class SampleProgressbar extends SampleBlock {
  const SampleProgressbar({required void Function(BlockType type) onPressed})
      : super(onPressed: onPressed);

  @override
  BlockType get blockType => BlockType.progressbar;

  @override
  Widget build(BuildContext context) {
    return super.content(LineIcons.lineChart, Colors.purple);
  }
}

class SampleContributors extends SampleBlock {
  const SampleContributors({required void Function(BlockType type) onPressed})
      : super(onPressed: onPressed);

  @override
  BlockType get blockType => BlockType.contributors;

  @override
  Widget build(BuildContext context) {
    return super.content(LineIcons.users, Colors.orange);
  }
}

class SampleAttendees extends SampleContributors {
  const SampleAttendees({required void Function(BlockType type) onPressed})
      : super(onPressed: onPressed);

  @override
  BlockType get blockType => BlockType.attendees;
}

class SampleEventTime extends SampleBlock {
  const SampleEventTime({required void Function(BlockType type) onPressed})
      : super(onPressed: onPressed);

  @override
  BlockType get blockType => BlockType.eventTime;

  @override
  Widget build(BuildContext context) {
    return super.content(LineIcons.clock, Colors.amberAccent);
  }
}

class SampleLink extends SampleBlock {
  const SampleLink({required void Function(BlockType type) onPressed})
      : super(onPressed: onPressed);

  @override
  BlockType get blockType => BlockType.link;

  @override
  Widget build(BuildContext context) {
    return super.content(LineIcons.link, Colors.cyan);
  }
}
