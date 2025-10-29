import 'dart:io';

import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//**import 'package:image_picker/image_picker.dart';

class TestFilePage extends ConsumerStatefulWidget {
  const TestFilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<TestFilePage> createState() => _TestFilePageState();
}

class _TestFilePageState extends ConsumerState<TestFilePage> {

  @override
  void initState() {
    super.initState();
    Auth myAccount = ref.read(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    Auth myAccount = ref.watch(authProvider);
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //MetaCard('Permissions', Permissions()),
                  MetaCard(
                    '１：未設定',
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          child: const Text('ファイル選択'),
                          onPressed: () async {
                            try {
                              /**FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                              if (result == null) throw Exception('file:null');
                              List<File> files = result.paths.map((path) => File(path!)).toList();
                              FunctionUtils.log(files);**/
                            } catch (e) {
                              FunctionUtils.log('Failed to pick file: $e');
                            }
                          }
                      ),
                    ),
                  ),
                  MetaCard(
                    '２：拡張子指定',
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              child: const Text('ファイル選択'),
                              onPressed: () async {
                                try {
                                  /**FilePickerResult? result = await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'pdf',
                                      'jpeg',
                                      'jpg',
                                      'png',
                                      'gif',
                                      'mp4',
                                      'mp3'
                                    ],
                                  );
                                  if (result == null) throw Exception('file:null');
                                  List<File> files = result.paths.map((path) => File(path!)).toList();
                                  FunctionUtils.log(files);**/
                                } catch (e) {
                                  FunctionUtils.log('Failed to pick file: $e');
                                }
                              }
                          ),
                        ),
                        const Text('pdf,jpeg,jpg,png,gif,mp4,mp3')
                      ],
                    ),
                  ),
                  MetaCard(
                    '３：画像タイプ',
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              child: const Text('ファイル選択'),
                              onPressed: () async {
                                try {
                                  /*FilePickerResult? result = await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.image
                                  );
                                  if (result == null) throw Exception('file:null');
                                  List<File> files = result.paths.map((path) => File(path!)).toList();
                                  FunctionUtils.log(files);*/
                                } catch (e) {
                                  FunctionUtils.log('Failed to pick file: $e');
                                }
                              }
                          ),
                        )
                      ],
                    ),
                  ),
                  MetaCard(
                    '４：カメラ撮影',
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              child: const Text('起動'),
                              onPressed: () async {
                                try {
                                  final pickedFile = null;//await ImagePicker().pickImage(source: ImageSource.camera);
                                  if (pickedFile == null) throw Exception('file:null');
                                  File file = File(pickedFile.path);
                                  await EasyLoading.showToast(file.path);
                                  FunctionUtils.log(file);
                                } catch (e) {
                                  FunctionUtils.log('Failed to pick file: $e');
                                }
                              }
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// UI Widget for displaying metadata.
class MetaCard extends StatelessWidget {
  final String _title;
  final Widget _children;

  // ignore: public_member_api_docs
  MetaCard(this._title, this._children);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                alignment: Alignment.centerLeft,
                child: Text(_title, style: const TextStyle(fontSize: 18)),
              ),
              _children,
            ],
          ),
        ),
      ),
    );
  }
}
