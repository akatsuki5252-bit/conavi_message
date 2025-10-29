import 'dart:io';
import 'dart:typed_data';

import 'package:conavi_message/utils/function_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class ImageFile {
  File file;
  bool isFileSizeOver = false;
  bool isCompress = true;

  ImageFile({required this.file, required this.isCompress});
}

class ChoiceImagePage extends StatefulWidget {
  final String fileName;
  final bool multipleType;
  final double limitFileSize;
  const ChoiceImagePage({super.key,required this.fileName,required this.multipleType,required this.limitFileSize});

  @override
  State<ChoiceImagePage> createState() => _ChoiceImagePageState();
}

class _ChoiceImagePageState extends State<ChoiceImagePage>{
  bool _multipleType = false; //複数選択
  double _limitFileSize = 5.0; //ファイルサイズ制限
  final int _maxSelectedFileNum = 5; //アップロード数制限
  List<XFile>? _pickedFileList; //取得ファイルリスト
  List<ImageFile>? _imageFileList; //表示ファイルリスト
  String _selectedFileSize = '';  //選択ファイルサイズ
  int? _radioIndex; //選択ラジオボタン順番値
  bool _isWarningFileSize = false;  //警告：ファイルサイズ
  bool _isWarningSelectedQuantity = false;  //警告：アップロード数
  bool _isCompressButton = false; //圧縮ボタンフラグ
  bool _isFirstPreview = false; //初回画像表示フラグ

  @override
  void initState() {
    super.initState();
    _multipleType = widget.multipleType;
    _limitFileSize = widget.limitFileSize;
    //ライブラリを起動
    pickImages();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //画像選択後のビルド後に再度ビルドを行う為にsetState（imageキャッシュ対策）
      if(_isFirstPreview) {
        setState(() {
          _isFirstPreview = false;
        });
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '画像選択',
          style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              pickImages();
            },
            child: const Text('選択', style: TextStyle(color:Colors.amber,fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: _imageFileList != null && _imageFileList!.isNotEmpty
          ? SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Visibility(
                    visible: _isWarningFileSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '${_limitFileSize}MB以上の画像をアップロードする事はできません',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _isWarningSelectedQuantity,
                    child: Padding(
                      padding: _isWarningFileSize == true
                          ? const EdgeInsets.only(bottom: 10)
                          : const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '最大アップロード数は$_maxSelectedFileNumつとなります',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  Flexible(
                    child: _imageFileList!.length == 1
                        ? Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                                child: Container(
                                    decoration: BoxDecoration(
                                      border: _imageFileList![0].isFileSizeOver == false
                                        ? null
                                        : Border.all(
                                          color: Colors.red),
                                    ),
                                    child: widgetImageFile(_imageFileList![0].file.path,false)
                                ),
                                // child: Image.file(
                                //   File(_imageFileList![0].file.path),
                                //   fit: BoxFit.cover,
                                //   key: UniqueKey(),
                                // ),
                              ),
                              // Align(
                              //   alignment: Alignment.topRight,
                              //   child: Theme(
                              //     data: Theme.of(context).copyWith(
                              //       unselectedWidgetColor: _imageFileList![0].isFileSizeOver == true
                              //               ? Colors.red
                              //               : Colors.white,
                              //     ),
                              //     child: Transform.scale(
                              //       scale: 1.5,
                              //       child: Radio(
                              //         activeColor: Colors.amber,
                              //         value: 0,
                              //         groupValue: _radioIndex,
                              //         onChanged: (value) {
                              //           var index = int.parse(value.toString());
                              //           var img =
                              //               File(_imageFileList![0].file.path);
                              //           final fileSize =
                              //               FunctionUtils.formatFileSize(img
                              //                   .readAsBytesSync()
                              //                   .lengthInBytes
                              //                   .toDouble());
                              //           setState(() {
                              //             _radioIndex = index;
                              //             _isCompressButton = _imageFileList![0].isCompress;
                              //             _selectedFileSize = fileSize;
                              //           });
                              //         },
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          )
                        : GridView.builder(
                            cacheExtent: 10000,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, //カラム数
                            ),
                            itemCount: _imageFileList!.length,
                            itemBuilder: (BuildContext context, int index) {
                              ImageFile imgFile = _imageFileList![index];
                              //var img = File(imgFile.file.path);
                              //final fileSize = FunctionUtils.formatFileSize(img.readAsBytesSync().lengthInBytes.toDouble());
                              //FunctionUtils.log(fileSize);
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    width: double.infinity / 3,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      border: imgFile.isFileSizeOver == false
                                          ? null
                                          : Border.all(
                                          color: Colors.red),
                                    ),
                                    child: _isFirstPreview == true
                                      ? widgetImageFile(imgFile.file.path,true)
                                      : Image.file(File(imgFile.file.path), fit: BoxFit.cover)
                                  ),
                                  Positioned(
                                    width: 25,
                                    height: 25,
                                    top: 0,
                                    right: 0,
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        unselectedWidgetColor:
                                            imgFile.isFileSizeOver == true
                                                ? Colors.red
                                                : Colors.white,
                                      ),
                                      child: Radio(
                                        activeColor: Colors.amber,
                                        value: index,
                                        groupValue: _radioIndex,
                                        onChanged: (value) {
                                          var index = int.parse(value.toString());
                                          var img = File(imgFile.file.path);
                                          final fileSize = FunctionUtils.formatFileSize(img.readAsBytesSync().lengthInBytes.toDouble());
                                          //FunctionUtils.log(imgFile.isCompress);
                                          setState(() {
                                            _radioIndex = index;
                                            _isCompressButton = imgFile.isCompress;
                                            _selectedFileSize = fileSize;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 55),
                ],
              ),
          )
          : const Center(
              child: Text('画像を選択してください'),
              // child: ElevatedButton.icon(
              //   icon: const Icon(Icons.image),
              //   label: const Text("画像を選択"),
              //   style: ElevatedButton.styleFrom(
              //     primary: Colors.amber, // background
              //   ),
              //   onPressed: () {
              //     pickImages();
              //   },
              // ),
            ),
      bottomSheet: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            //圧縮
            ElevatedButton(
              onPressed: _isCompressButton == false
                  ? null
                  : () async {
                      //初期化
                      _isWarningFileSize = false;
                      _isWarningSelectedQuantity = false;
                      //ローディング
                      EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
                      EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
                      EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
                      await EasyLoading.show(
                        status: '圧縮中...',
                        dismissOnTap: false,
                        maskType: EasyLoadingMaskType.black,
                      );
                      try {
                        final List<ImageFile> compressFileList = [];
                        String? fileSize;
                        for (int i = 0; i < _imageFileList!.length; i++) {
                          ImageFile imgFile = ImageFile(file: File(_imageFileList![i].file.path),isCompress: _imageFileList![i].isCompress);
                          if(i == _radioIndex) {
                            Uint8List? fixedImageBytesO;fixedImageBytesO = await compressFile(imgFile.file, 50);
                            if (fixedImageBytesO == null) return;
                            imgFile.file.writeAsBytesSync(fixedImageBytesO);
                            fileSize = FunctionUtils.formatFileSize(imgFile.file.readAsBytesSync().lengthInBytes.toDouble());
                            //FunctionUtils.log(fileSize);
                            imgFile.isCompress = false;
                          }
                          imgFile.isFileSizeOver = checkFileSize(imgFile.file.readAsBytesSync().lengthInBytes.toDouble(),_limitFileSize);
                          if(imgFile.isFileSizeOver) _isWarningFileSize = true;
                          compressFileList.add(imgFile);
                        }
                        setState(() {
                          _imageFileList = compressFileList;
                          _isCompressButton = false;
                          if (fileSize != null) _selectedFileSize = fileSize;
                        });
                      } catch (e) {
                        FunctionUtils.log('Failed to pick image: $e');
                      } finally {
                        EasyLoading.dismiss();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, // background
              ),
              child: const Text('圧縮'),
            ),
            Expanded(
              child: Center(child: Text(_selectedFileSize)),
            ),
            ElevatedButton(
              onPressed: _imageFileList == null || _isWarningFileSize ? null : () {
                Navigator.pop(context, _imageFileList);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, // background
              ),
              child: const Text('完了'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget widgetImageFile(String path,bool multiType){
    File file = File(path);
    final imageForUint8 = file.readAsBytesSync();
    return Image.memory(imageForUint8,fit: multiType == true ? BoxFit.cover : BoxFit.contain);
  }

  // 画像をギャラリーから選ぶ関数
  Future pickImages() async {
    //初期化
    _imageFileList = null;
    _selectedFileSize = '';
    _radioIndex = null;
    _isWarningFileSize = false;
    _isWarningSelectedQuantity = false;
    _isFirstPreview = true;
    bool isComplete = false;
    //ローディング
    EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
    EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
    EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
    await EasyLoading.show(
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.black,
    );
    FunctionUtils.log('start');
    try {
      if(_multipleType == true) {
        _pickedFileList = await ImagePicker().pickMultiImage();
      }else{
        final image  = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (image == null) return;
        _pickedFileList = [image];
        FunctionUtils.log(_pickedFileList);
      }

      if(_pickedFileList == null) return;

      final List<ImageFile> compressFileList = [];
      int index = 0;
      for(var image in _pickedFileList!){
        if(index >= _maxSelectedFileNum){
          _isWarningSelectedQuantity = true;
          break;
        }
        //ファイル名を変更「ルームid_日付_index.拡張子」（※既存のファイル名は使用不可）
        File file = File(image.path);
        String dir = path.dirname(file.path);
        String ext = path.extension(file.path);
        DateTime now = DateTime.now();
        DateFormat outputFormat = DateFormat('yyyyMMddHm');
        String date = outputFormat.format(now);
        String newPath = path.join(dir, '${widget.fileName}_${date}_${index+1}$ext');
        File newFile = await file.renameSync(newPath);  //名前の変更
        FunctionUtils.log('rename前: ${file.path}');
        FunctionUtils.log('rename後: ${newFile.path}');

        ImageFile imgFile = ImageFile(file: newFile,isCompress: true);

        final Uint8List? fixedImageBytesO = await compressFile(imgFile.file,100);
        if(fixedImageBytesO == null) continue;
        imgFile.file.writeAsBytesSync(fixedImageBytesO);

        imgFile.isFileSizeOver = checkFileSize(imgFile.file.readAsBytesSync().lengthInBytes.toDouble(),_limitFileSize);
        if(imgFile.isFileSizeOver) _isWarningFileSize = true;

        compressFileList.add(imgFile);
        index++;
      }
      //FunctionUtils.log(pickedFileList);
      setState(() {
        _imageFileList = compressFileList;
        //単一の画像の場合、圧縮ボタン、ファイルサイズを初期表示させる
        if(_imageFileList != null && _imageFileList!.length == 1){
          _radioIndex = 0;
          for(var image in _imageFileList!) {
            _selectedFileSize = FunctionUtils.formatFileSize(image.file.readAsBytesSync().lengthInBytes.toDouble());
          }
          _isCompressButton = _imageFileList![0].isCompress;
        }
      });
      isComplete = true;
    } catch (e) {
      FunctionUtils.log('Failed to pick image: $e');
    } finally {
      if(!isComplete){
        //setState((){});
      }
      EasyLoading.dismiss();
    }
    FunctionUtils.log('pickImage:end');
  }

  Future<Uint8List?> compressFile(File file,int quality) async {
    FunctionUtils.log('compressFile');
    final size = ImageSizeGetter.getSize(FileInput(file));
    final fileSize = file.readAsBytesSync().lengthInBytes.toDouble();
    FunctionUtils.log('width:${size.width},height:${size.height},size:${fileSize}');
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: size.width,
      minHeight: size.height,
      rotate: 0,
      quality: quality,
      keepExif: false,
      autoCorrectionAngle: true,
      //format: CompressFormat.jpeg,
    );
    return result;
  }

  bool checkFileSize(double size,double limitSize) {
    //FunctionUtils.log(size);
    //MB
    double m = ((size / 1024.0) / 1024.0);
    if (m > 1) {
      limitSize = limitSize * 1000000;
      if(size > limitSize){
        return true;
      }else{
        return false;
      }
    } else {
      return false;
    }
  }

}