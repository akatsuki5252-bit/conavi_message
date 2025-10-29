import 'dart:io';
import 'dart:typed_data';

import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class PickerFile {
  File file; //ファイル
  bool isFileSizeOverFlag = false; //容量サイズオーバー
  bool isCompressFlag = true; //圧縮
  bool isImageFlag = false; //画像判定
  Icon cardIcon = const Icon(Icons.insert_drive_file,size: 40, color: Colors.amber);
  String cardName = 'その他ファイル';
  PickerFile({
    required this.file,
  }){
    String extension = path.extension(file.path);
    if(extension.toLowerCase() == '.png' ||
        extension.toLowerCase() == '.jpg' || extension.toLowerCase() == '.jpeg' ||
        extension.toLowerCase() == '.gif') {
      isImageFlag = true;
    }else{
      isCompressFlag = false;
      if(extension.toLowerCase() == '.mp4'){
        cardIcon = const Icon(Icons.movie,size: 40, color: Colors.amber);
        cardName = '動画ファイル';
      }else if(extension.toLowerCase() == '.mp3'){
        cardIcon = const Icon(Icons.headphones,size: 40, color: Colors.amber);
        cardName = '音声ファイル';
      }else if(extension.toLowerCase() == '.pdf'){
        cardIcon = const Icon(Icons.picture_as_pdf,size: 40, color: Colors.amber);
        cardName = 'PDFファイル';
      }
    }
  }
}

class FilePickerPage extends StatefulWidget {
  final MessageFileType fileType;
  final bool multipleType;
  final double limitImageFileSize;
  final double limitFileSize;
  const FilePickerPage({
    super.key,
    required this.fileType,
    required this.multipleType,
    required this.limitImageFileSize,
    required this.limitFileSize});

  @override
  State<FilePickerPage> createState() => _FilePickerPageState();
}

class _FilePickerPageState extends State<FilePickerPage>{

  final int _maxSelectedFileNum = 5; //アップロード数制限
  List<PickerFile>? _pickerFiles; //表示ファイルリスト
  bool _multipleType = false; //複数選択
  double _limitFileSize = 0.0; //ファイルサイズ制限
  double _limitImageFileSize = 0.0; //画像ファイルサイズ制限
  String _selectedFileSize = '';  //選択ファイルサイズ
  int? _radioIndex; //選択ラジオボタン順番値
  bool _isWarningFileSize = false;  //警告：ファイルサイズ
  bool _isWarningImageFileSize = false;  //警告：画像ファイルサイズ
  bool _isWarningSelectedQuantity = false;  //警告：アップロード数
  bool _isCompressButton = false; //圧縮ボタンフラグ
  bool _isFirstPreview = false; //初回画像表示フラグ

  @override
  void initState() {
    super.initState();
    _multipleType = widget.multipleType;
    _limitFileSize = widget.limitFileSize;
    _limitImageFileSize = widget.limitImageFileSize;
    //ライブラリを起動
    //pickImages();
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
        title: Text(
          widget.fileType == MessageFileType.image ? '画像選択' : 'ファイル選択',
          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              pickFiles();
            },
            child: const Text('選択', style: TextStyle(color:Colors.amber,fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: _pickerFiles != null &&_pickerFiles!.isNotEmpty
          ? SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Visibility(
                    visible: _isWarningFileSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
                      child: Text(
                        '[${_limitFileSize}MB]以上のファイルをアップロードする事はできません',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _isWarningImageFileSize,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
                      child: Text(
                        '[${_limitImageFileSize}MB]以上の画像をアップロードする事はできません',
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
                    child: _pickerFiles!.length == 1
                        ? Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                                child: Container(
                                    decoration: BoxDecoration(
                                      border: _pickerFiles![0].isFileSizeOverFlag == false
                                        ? null
                                        : null//Border.all(color: Colors.red),
                                    ),
                                    child: widgetFile(_pickerFiles![0],false,false)
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
                            itemCount: _pickerFiles!.length,
                            itemBuilder: (BuildContext context, int index) {
                              PickerFile pickerFile = _pickerFiles![index];
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    width: double.infinity / 3,
                                    height: 300,
                                    margin: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      border: pickerFile.isFileSizeOverFlag == false
                                          ? null
                                          : Border.all(color: Colors.red),
                                    ),
                                    child: widgetFile(pickerFile,true,_isFirstPreview),
                                  ),
                                  Positioned(
                                    width: pickerFile.isImageFlag ? 25 : 35,
                                    height: pickerFile.isImageFlag ? 25 : 35,
                                    top: 0,
                                    right: 0,
                                    child: Theme(
                                      data: Theme.of(context).copyWith(unselectedWidgetColor: pickerFile.isFileSizeOverFlag == true
                                                ? Colors.red
                                                : Colors.amber,
                                      ),
                                      child: Radio(
                                        activeColor: Colors.amber,
                                        value: index,
                                        groupValue: _radioIndex,
                                        onChanged: (value) {
                                          var index = int.parse(value.toString());
                                          var img = File(pickerFile.file.path);
                                          final fileSize = FunctionUtils.formatFileSize(img.readAsBytesSync().lengthInBytes.toDouble());
                                          //FunctionUtils.log(imgFile.isCompress);
                                          setState(() {
                                            _radioIndex = index;
                                            _isCompressButton = pickerFile.isCompressFlag;
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
          : Center(
              child: Text( widget.fileType == MessageFileType.image
                  ? '画像を選択してください'
                  : 'ファイルを選択してください'
              ),
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
                      _isWarningImageFileSize = false;
                      _isWarningSelectedQuantity = false;
                      //ローディング
                      Loading.show(message: '圧縮中...', isDismissOnTap: false);
                      try {
                        if(_pickerFiles != null) {
                          final List<PickerFile> compressFileList = [];
                          String? fileSize;
                          for (int i = 0; i < _pickerFiles!.length; i++) {
                            PickerFile pickerFile = PickerFile(file: _pickerFiles![i].file);
                            pickerFile.isCompressFlag = _pickerFiles![i].isCompressFlag;
                            if (i == _radioIndex && pickerFile.isImageFlag) {
                              final Uint8List? fixedImageBytesO = await compressFile(pickerFile.file, 50);
                              if (fixedImageBytesO == null) continue;
                              pickerFile.file.writeAsBytesSync(fixedImageBytesO);
                              fileSize = FunctionUtils.formatFileSize(pickerFile.file.readAsBytesSync().lengthInBytes.toDouble());
                              pickerFile.isCompressFlag = false;
                            }
                            pickerFile.isFileSizeOverFlag = FunctionUtils.checkFileSize(pickerFile.file.readAsBytesSync().lengthInBytes.toDouble(), _limitImageFileSize);
                            if (pickerFile.isFileSizeOverFlag) _isWarningImageFileSize = true;
                            compressFileList.add(pickerFile);
                          }
                          setState(() {
                            _pickerFiles = compressFileList;
                            _isCompressButton = false;
                            if (fileSize != null) _selectedFileSize = fileSize;
                          });
                        }
                      } catch (e) {
                        FunctionUtils.log('Failed to pick image: $e');
                      } finally {
                        Loading.dismiss();
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
              onPressed: _pickerFiles == null || _isWarningFileSize ? null : () {
                Navigator.pop(context, _pickerFiles);
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
  
  Widget widgetFile(PickerFile pickerFile,bool isMultiType,bool isFirst){
    if(pickerFile.isImageFlag) {
      if(isFirst) {
        final imageForUint8 = pickerFile.file.readAsBytesSync();
        return Image.memory(imageForUint8, fit: isMultiType == true ? BoxFit.cover : BoxFit.contain);
      }else{
        return Image.file(pickerFile.file, fit: BoxFit.cover);
      }
    }else{
      return Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.33,
            maxHeight: 180
        ),
        child: Card(
          color: Colors.white,
          //margin: const EdgeInsets.all(30),
          elevation: 8,
          shadowColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: isMultiType ? const EdgeInsets.all(10) : const EdgeInsets.all(15),
            child: Stack(
              children: [
                Center(
                    child: pickerFile.cardIcon,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(pickerFile.cardName,style: const TextStyle(fontSize: 11)),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  void init(){
    _pickerFiles = [];
    _selectedFileSize = '';
    _radioIndex = null;
    _isWarningFileSize = false;
    _isWarningImageFileSize = false;
    _isWarningSelectedQuantity = false;
    _isFirstPreview = true;
    setState(() {});
  }

  //ファイルピッカーライブラリからをファイルを選択
  Future pickFiles() async {
    //初期化
    init();
    //ローディングメッセージを表示
    Loading.show(message: '選択中...', isDismissOnTap: false);
    try {
      late FilePickerResult? result;
      //画像
      if(widget.fileType == MessageFileType.image) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          //allowedExtensions: ['jpg','jpeg','png','gif'],
          allowMultiple: _multipleType,
          compressionQuality:0,
        );
      }else if(widget.fileType == MessageFileType.file){
        result = await FilePicker.platform.pickFiles(
          allowMultiple: _multipleType,
          compressionQuality:0,
        );
      }
      if (result == null) throw Exception('file:null');
      List<File> files = result.paths.map((path) => File(path!)).toList();
      FunctionUtils.log(files);

      // if(_multipleType == true) {
      //   _pickedFileList = await ImagePicker().pickMultiImage();
      // }else{
      //   final image  = await ImagePicker().pickImage(source: ImageSource.gallery);
      //   if (image == null) return;
      //   _pickedFileList = [image];
      //   FunctionUtils.log(_pickedFileList);
      // }
      //
      // if(_pickedFileList == null) return;
      //

      if(files.length > _maxSelectedFileNum) _isWarningSelectedQuantity = true;

      final List<PickerFile> compressFiles = [];
      int index = 0;
      for(var file in files){
        if(index >= _maxSelectedFileNum) break;
        //ファイル名を変更「日付-index.拡張子」（※既存のファイル名は使用不可）
        String dir = path.dirname(file.path);
        String ext = path.extension(file.path);
        if (ext.isEmpty) throw Exception('file:not extension');
        DateTime now = DateTime.now();
        DateFormat outputFormat = DateFormat('yyyyMMddHm');
        String date = outputFormat.format(now);
        String renamePath = path.join(dir, '$date-${index+1}$ext');
        File renameFile = file.renameSync(renamePath);  //名前の変更
        FunctionUtils.log('rename前: ${file.path}');
        FunctionUtils.log('rename後: ${renameFile.path}');

        PickerFile pickerFile = PickerFile(file: renameFile);
        if(pickerFile.isImageFlag) {
          final Uint8List? fixedImageBytesO = await compressFile(pickerFile.file, 100);
          if (fixedImageBytesO == null) continue;
          pickerFile.file.writeAsBytesSync(fixedImageBytesO);
          pickerFile.isFileSizeOverFlag = FunctionUtils.checkFileSize(pickerFile.file.readAsBytesSync().lengthInBytes.toDouble(),_limitImageFileSize);
          if(pickerFile.isFileSizeOverFlag) _isWarningImageFileSize = true;
        }else{
          pickerFile.isFileSizeOverFlag = FunctionUtils.checkFileSize(pickerFile.file.readAsBytesSync().lengthInBytes.toDouble(),_limitFileSize);
          if(pickerFile.isFileSizeOverFlag) _isWarningFileSize = true;
        }

        compressFiles.add(pickerFile);
        index++;
      }
      //FunctionUtils.log(pickedFileList);
      setState(() {
        _pickerFiles = compressFiles;
        //単一の画像の場合、圧縮ボタン、ファイルサイズを初期表示させる
        if(_pickerFiles != null && _pickerFiles!.length == 1){
          _radioIndex = 0;
          for(var pickerFile in _pickerFiles!) {
            _selectedFileSize = FunctionUtils.formatFileSize(pickerFile.file.readAsBytesSync().lengthInBytes.toDouble());
            _isCompressButton = pickerFile.isCompressFlag;
          }
        }
      });
    } catch (e) {
      FunctionUtils.log('Failed to pick file: $e');
      setState(() {
        _pickerFiles = null;
        _isCompressButton = false;
      });
    } finally {
      //ローディングを終了
      Loading.dismiss();
    }
    FunctionUtils.log(_pickerFiles);
    FunctionUtils.log('pickFiles:end');
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

}
