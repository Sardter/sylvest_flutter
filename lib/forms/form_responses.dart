import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flowder/flowder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sylvest_flutter/home/main_components.dart';
import 'package:uuid/uuid.dart';

import '../services/api.dart';
import '../services/image_service.dart';

class FormResponsesModal extends StatefulWidget {
  const FormResponsesModal({Key? key, required this.postId}) : super(key: key);
  final int postId;

  @override
  State<FormResponsesModal> createState() => _FormResponsesModalState();
}

class _FormResponsesModalState extends State<FormResponsesModal> {
  List<FormResponse> _responses = [];
  bool _loading = false;

  Future<void> _getResponses() async {
    setState(() {
      _loading = true;
    });
    final responses = await API().getFormResponses(context, widget.postId);
    setState(() {
      _responses = responses;
      _loading = false;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getResponses();
    });
    super.initState();
  }

  @override
  Widget build(context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      controller: ModalScrollController.of(context),
      child: Column(
        children: const <Widget>[
          Text('Responses',
              style: TextStyle(fontFamily: 'Quicksand', fontSize: 18)),
          SizedBox(
            height: 10,
          )
        ] +
            _responses + [if (_loading) LoadingIndicator()],
      ),
    );
  }
}

class FormResponse extends StatelessWidget {
  final String author;
  final String? authorImageUrl;
  final int postPk;
  final int? sentToken;
  final Map data;
  final String? file;
  final Map? fileDetails;
  final DateTime datePosted;

  const FormResponse(
      {Key? key,
      required this.author,
      required this.authorImageUrl,
      required this.postPk,
      required this.sentToken,
      required this.data,
      required this.fileDetails,
      required this.datePosted,
      required this.file})
      : super(key: key);

  factory FormResponse.fromJson(Map json) {
    return FormResponse(
        author: json['author'],
        authorImageUrl: json['author_image'],
        postPk: json['post'],
        sentToken: json['sent_token'],
        file: json['file'],
        fileDetails: json['file_details'],
        data: json['data'],
        datePosted: DateTime.parse(json['date_posted']));
  }

  List<Widget> _responseItems() {
    return (data['formItems'] as List).map<Widget>((response) {
      switch (response['name']) {
        case 'short_text':
          return ShortFormResponse(
              name: response['name'],
              question: response['question'],
              required: response['required'],
              data: response['data']);
        case 'long_text':
          return LongFormResponse(
              name: response['name'],
              question: response['question'],
              required: response['required'],
              data: response['data']);
        case 'check_box':
          return CheckBoxFormResponse(
              name: response['name'],
              question: response['question'],
              required: response['required'],
              data: response['data']);
        case 'multiple_choice':
          return MultipleChoiceFormResponse(
              name: response['name'],
              question: response['question'],
              required: response['required'],
              data: response['data']['options']);
        case 'file':
          return FileFormResponse(
              name: response['name'],
              question: response['question'],
              required: response['required'],
              data: fileDetails);
        case 'fundable':
          return FundingFormResponse(
              name: response['name'],
              question: response['question'],
              required: response['required'],
              data: response['data']);
        default:
          throw Exception('Unexpected type: ${response['name']}');
      }
    }).toList();
  }

  // void _onTap(context) {
  //   Navigator.push(context,
  //       MaterialPageRoute(builder: (context) => PostDetailPage(postPk)));
  // }

  @override
  Widget build(context) {
    return InkWell(
      //onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, spreadRadius: 2, blurRadius: 5)
            ]),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
                Row(
                  children: [
                    Expanded(
                        child: Row(children: [
                      SylvestImageProvider(
                        url: authorImageUrl,),
                      const SizedBox(width: 10),
                      Text(author,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ])),
                    IconButton(icon: Icon(Icons.more_horiz), onPressed: () {})
                  ],
                ),
              ] +
              _responseItems(),
        ),
      ),
    );
  }
}

class Response {
  final String name, question;
  final bool required;
  final dynamic data;

  Widget questionWidget() {
    return Row(
      children: [
        const SizedBox(width: 8),
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  const Response(
      {required this.name,
      required this.question,
      required this.required,
      required this.data});
}

class ShortFormResponse extends StatelessWidget implements Response {
  const ShortFormResponse(
      {Key? key,
      required this.name,
      required this.question,
      required this.required,
      required this.data})
      : super(key: key);

  @override
  final String name, question;
  final bool required;
  final String? data;

  Widget questionWidget() {
    return Row(
      children: [
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          questionWidget(),
          Divider(),
          data != null
              ? Text(data!)
              : Text(
                  "No Response",
                  style: TextStyle(color: Colors.black54),
                )
        ],
      ),
    );
  }
}

class LongFormResponse extends StatelessWidget implements Response {
  const LongFormResponse(
      {Key? key,
      required this.name,
      required this.question,
      required this.required,
      required this.data})
      : super(key: key);

  @override
  final String name, question;
  final bool required;
  final String data;

  Widget questionWidget() {
    return Row(
      children: [
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [questionWidget(), Divider(), Text(data)],
      ),
    );
  }
}

class FundingFormResponse extends StatelessWidget implements Response {
  const FundingFormResponse(
      {Key? key,
      required this.name,
      required this.question,
      required this.required,
      required this.data})
      : super(key: key);

  @override
  final String name, question;
  final bool required;
  final Map data;

  Widget questionWidget() {
    return Row(
      children: [
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          questionWidget(),
          Divider(),
          Text.rich(TextSpan(children: [
            TextSpan(
                text: data['fund'] == null
                    ? null
                    : '${(data['fund'] as double).toInt()} SYLK',
                style: TextStyle(
                    color: const Color(0xFF733CE6), fontFamily: 'Quicksand')),
            TextSpan(
                text:
                    data['fund'] == null ? 'No SYLK was funded' : ' was funded')
          ]))
        ],
      ),
    );
  }
}

class CheckBoxFormResponse extends StatelessWidget implements Response {
  const CheckBoxFormResponse(
      {Key? key,
      required this.name,
      required this.question,
      required this.required,
      required this.data})
      : super(key: key);

  @override
  final String name, question;
  final bool required;
  final List data;

  Widget questionWidget() {
    return Row(
      children: [
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _option(Map data) {
    return Row(
      children: [
        Checkbox(value: data['selected'], onChanged: null),
        Text(data['label'])
      ],
    );
  }

  List<Widget> _options() {
    return data.map<Widget>((e) => _option(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              questionWidget(),
              Divider(),
            ] +
            _options(),
      ),
    );
  }
}

class MultipleChoiceFormResponse extends StatelessWidget implements Response {
  const MultipleChoiceFormResponse(
      {Key? key,
      required this.name,
      required this.question,
      required this.required,
      required this.data})
      : super(key: key);

  @override
  final String name, question;
  final bool required;
  final List data;

  Widget questionWidget() {
    return Row(
      children: [
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _option(Map data) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 3)
        ],
        borderRadius: BorderRadius.circular(30),
        color: data['is_selected'] ? const Color(0xFF8d61ea) : Colors.white,
      ),
      margin: const EdgeInsets.symmetric(vertical: 5),
      width: double.maxFinite,
      padding: const EdgeInsets.all(5),
      child: Text(
        data['text'],
        textAlign: TextAlign.center,
        style:
            TextStyle(color: data['is_selected'] ? Colors.white : Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
              questionWidget(),
              Divider(),
            ] +
            data.map<Widget>((e) => _option(e)).toList(),
      ),
    );
  }
}

class FileFormResponse extends StatelessWidget implements Response {
  const FileFormResponse(
      {Key? key,
      required this.name,
      required this.question,
      required this.required,
      required this.data})
      : super(key: key);
  @override
  final String name, question;
  final bool required;
  final Map? data;

  Widget questionWidget() {
    return Row(
      children: [
        if (required)
          Text('⬤', style: TextStyle(color: const Color(0xFF8d61ea))),
        if (required) const SizedBox(width: 8),
        Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<File?> _getFile() async {
    if (data == null) return null;
    final pathToStore = await _getDownloadPath();
    final fileName = Uuid().v4();
    await Flowder.download(
        data!['url'],
        DownloaderUtils(
            progress: ProgressImplementation(),
            file: File('$pathToStore/$fileName'),
            onDone: () => print('Download done'),
            progressCallback: (current, total) {
              final progress = (current / total) * 100;
              print('Downloading: $progress');
            }));
    return File('$pathToStore/$fileName');
  }

  Future<String> _getDownloadPath() async {
    Directory? directory;
    directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Widget _filewidget() {
    if (data == null) return Text("No file was uploaded");
    return Row(
      children: [
        Text(data!['name']),
        SizedBox(
          width: 5,
        ),
        Text(data!['size'],
            style: TextStyle(fontSize: 12, color: Colors.black26)),
        Expanded(
            child: IconButton(
                alignment: Alignment.centerRight,
                onPressed: () async {
                  final file = await _getFile();
                  await OpenFile.open(file!.path);
                },
                icon: Icon(Icons.download_rounded,
                    color: const Color(0xFF8d61ea))))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [questionWidget(), Divider(), _filewidget()],
      ),
    );
  }
}
