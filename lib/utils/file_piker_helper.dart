import 'dart:io';
import 'dart:typed_data';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart' as intl;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PickerFile {
  File file;
  Uint8List bytes;
  String fileName;
  int size;

  PickerFile({
    required this.file,
    required this.bytes,
    required this.fileName,
    required this.size,
  });
}

class FilePickerHelper {

  // ファイルサイズ上限
  static const int maxMB = 5;
  static const int maxBytes = maxMB * 1024 * 1024;

  /// ファイル選択 & サイズ制限付き圧縮判定
  ///
  /// [type]        : 画像 or その他
  /// [maxBytes]    : サイズ上限（外部指定）
  /// [maxCount]    : 同時選択可能枚数
  /// [context]     : ダイアログ表示のため呼び出し元context渡す
  /// [onConfirm]   : 圧縮OK押されたときの処理
  /// [onCancel]    : キャンセルされたとき
  static Future<List<PickerFile>> pick({
    required MessageFileType type,
    bool allowMultiple = true,
    int maxCount = 5
  }) async {

    List<PickerFile> pickedFiles = [];

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type == MessageFileType.image ? FileType.image : FileType.any,
        allowMultiple: allowMultiple,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      // 複数選択の場合はmaxCountまで、単一選択の場合は1件のみ
      final paths = result.paths
          .whereType<String>()
          .take(allowMultiple ? maxCount : 1)
          .toList();

      for (int i = 0; i < paths.length; i++) {

        File file = File(paths[i]);

        /// リネーム（時間-index.拡張子）
        final dir = path.dirname(file.path);
        final ext = path.extension(file.path);
        final date = intl.DateFormat('yyyyMMddHHmmss').format(DateTime.now());
        final renamedPath = path.join(dir, '$date-${i + 1}$ext');
        try{
          file = await file.rename(renamedPath);
        }catch(e){
          print('File pick rename error: $e');
        }

        Uint8List? fileBytes = await file.readAsBytes();
        int size = fileBytes.length;

        pickedFiles.add(PickerFile(
          file: file,
          bytes: fileBytes,
          fileName: path.basename(file.path),
          size: size,
        ));
      }

    } catch (e) {
      print('File pick error: $e');
    }

    return pickedFiles;
  }

  static Future<bool> isCheckFileSize(
      MessageFileType type,
      File file,
      int maxBytes,
      ) async {
    try {
      final size = await file.length();
      //return type == MessageFileType.image && size > maxBytes;
      return size > maxBytes;
    } catch (_) {
      return false; // 読めない時はサイズNGとして false（判定しない）
    }
  }

  static Future<File> compressImageFile(
      File file, {
        int quality = 90
      }) async {
    try {
      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;

      // 元画像のメタデータ取得（幅・高さ）
      final sizeResult = ImageSizeGetter.getSizeResult(FileInput(file));
      final width = sizeResult.size.width.toInt();
      final height = sizeResult.size.height.toInt();

      FunctionUtils.log('[compress] Before: ${originalSize / 1024 ~/ 1} KB ($width x $height)');

      // 圧縮実行
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: width,     // 解像度は落とさず画質のみ調整
        minHeight: height,
        quality: quality,
        rotate: 0,
        keepExif: true,
        autoCorrectionAngle: true,
      );
      if (compressedBytes == null) {
        FunctionUtils.log('[compress] Failed: result null');
        return file;
      }
      file.writeAsBytesSync(compressedBytes);
      return file;
    } catch (e) {
      FunctionUtils.log('[compress] Error: $e');
      return file;
    }
  }

  static Future<File?> compressImageFileToLimit(
      File file,
      int maxBytes, {
        int quality = 100,
        int minQuality = 10,
  }) async {
    try {
      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;

      // 圧縮前に既に制限以下ならそのまま返す
      if (originalSize <= maxBytes) {
        return file;
      }

      // 元画像のメタデータ取得（幅・高さ）
      final sizeResult = ImageSizeGetter.getSizeResult(FileInput(file));
      final width = sizeResult.size.width.toInt();
      final height = sizeResult.size.height.toInt();

      FunctionUtils.log('[compress] Before: ${originalSize / 1024 ~/ 1} KB ($width x $height)');

      while (quality >= minQuality) {
        // 圧縮実行
        final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
          file.path,
          minWidth: width,     // 解像度は落とさず画質のみ調整
          minHeight: height,
          quality: quality,
          rotate: 0,
          keepExif: true,
          autoCorrectionAngle: true,
        );
        if (compressedBytes == null) {
          FunctionUtils.log('[compress] Failed: result null');
          break;
        }
        if (compressedBytes.length <= maxBytes) {
          file.writeAsBytesSync(compressedBytes);
          return file;
        }
        quality -= 10;
      }
      // quality 10でも上限以下にならなかった
      return null;
    } catch (e) {
      FunctionUtils.log('[compress] Error: $e');
      return null;
    }
  }

  /// サイズ超過ダイアログ
  static Future<bool?> _showOverDialog(
      BuildContext context,
      int size,
      int maxBytes,
      ) async {
    final sizeMB = (size / 1024 / 1024).toStringAsFixed(2);
    final maxMB = (maxBytes / 1024 / 1024).toStringAsFixed(2);

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ファイルサイズが大きすぎます'),
        content: Text(
            '選択したファイルは ${sizeMB}MB です。\n'
                '最大 ${maxMB}MB まで圧縮して送信しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('圧縮する'),
          ),
        ],
      ),
    );
  }

  static bool isCompressibleImage(File file) {
    final ext = path.extension(file.path).toLowerCase();

    return [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
    ].contains(ext);
  }

  static Future<List<File>> pickFilesWithSizeCheck({
    required BuildContext context,
    required MessageFileType type,
    bool allowMultiple = true,
  }) async {
    List<PickerFile> pickFiles = [];
    List<PickerFile> compressFiles = [];

    try {
      pickFiles = await pick(
        type: type,
        allowMultiple: allowMultiple,
      );

      if (pickFiles.isEmpty) {
        return [];
      }

      FunctionUtils.log(pickFiles);

      for (var pickFile in pickFiles) {

        // サイズオーバー
        if (await isCheckFileSize(type, pickFile.file, maxBytes)) {

          // 圧縮可能な画像
          if (isCompressibleImage(pickFile.file)) {

            final fileSizeBytes = await pickFile.file.length();
            final sizeMB = fileSizeBytes / (1024 * 1024);

            final result = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('ファイルサイズが大きすぎます'),
                content: Text(
                  '選択したファイルは ${sizeMB.toStringAsFixed(2)}MB です。\n'
                      '最大${maxMB}MB まで圧縮して送信しますか？',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('圧縮する'),
                  ),
                ],
              ),
            );

            if (result == true) {
              final file = await compressImageFileToLimit(
                pickFile.file,
                maxBytes,
              );

              if (file != null) {
                pickFile.file = file;
                compressFiles.add(pickFile);
              } else {
                FunctionUtils.showToast(
                  message: '圧縮エラー',
                  toastLength: Toast.LENGTH_SHORT,
                  toastGravity: ToastGravity.BOTTOM,
                  time: 1,
                  backgroundColor: const Color(0xff3166f7),
                  textColor: Colors.white,
                  textSize: 16.0,
                  cancelFlg: true,
                );
              }
            }

          } else {
            FunctionUtils.showToast(
              message: 'ファイルサイズオーバー',
              toastLength: Toast.LENGTH_SHORT,
              toastGravity: ToastGravity.BOTTOM,
              time: 1,
              backgroundColor: const Color(0xff3166f7),
              textColor: Colors.white,
              textSize: 16.0,
              cancelFlg: true,
            );
          }

        } else {

          // サイズ制限以内
          if (type == MessageFileType.image) {
            pickFile.file = await compressImageFile(pickFile.file);
          }

          compressFiles.add(pickFile);
        }
      }

      return compressFiles
          .map((compressFile) => File(compressFile.file.path))
          .toList();

    } catch (e) {
      FunctionUtils.log('Failed to pick file: $e');
      return [];
    }
  }
}