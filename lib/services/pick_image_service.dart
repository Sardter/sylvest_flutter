import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  XFile? _mediaFile;

  Future<void> _pickFromGallery(BuildContext context) async {
    _mediaFile = await _picker.pickImage(source: ImageSource.gallery);
    Navigator.pop(context);
  }

  Future<void> _pickVideo(BuildContext context) async {
    _mediaFile = await _picker.pickVideo(source: ImageSource.gallery);
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    _mediaFile = await _picker.pickImage(source: ImageSource.camera);
    Navigator.pop(context);
  }

  Future<XFile?> getImage(BuildContext context) async {
    await _chooseImageDialog(context);
    return _mediaFile;
  }

  Future<XFile?> getVideo(BuildContext context) async {
    await _pickVideo(context);
    return _mediaFile;
  }

  Future<void> _chooseImageDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            GestureDetector(
              onTap: () async {
                await _pickFromGallery(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const <Widget>[
                  SizedBox(height: 10),
                  Icon(LineIcons.photoVideo),
                  Text(
                    "Choose from gallery",
                    style: TextStyle(fontSize: 12),
                  )
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await _pickFromCamera(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const <Widget>[
                  SizedBox(height: 10),
                  Icon(LineIcons.camera),
                  Text(
                    "Take a picture",
                    style: TextStyle(fontSize: 12),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
