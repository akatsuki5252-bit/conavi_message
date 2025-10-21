import 'package:cached_network_image/cached_network_image.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageViewPage extends ConsumerStatefulWidget {
  final String url;
  final String fileName;
  const ImageViewPage(this.url,this.fileName,{super.key});

  @override
  ConsumerState<ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends ConsumerState<ImageViewPage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: (){
          setState(() {
            _isVisible = !_isVisible; //値を反転
          });
        },
        behavior: HitTestBehavior.opaque, //子要素のタップイベントを邪魔しない
        child: SafeArea(
          child: Stack(
            children: [
              InteractiveViewer(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  //child: Image.network(widget.imageUrl,fit: BoxFit.contain)
                  child: CachedNetworkImage(
                    maxHeightDiskCache: 1000,
                    imageUrl: widget.url,
                    placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: CircularProgressIndicator(
                              color: Colors.amber
                          ),
                        )
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                  alignment: Alignment.topLeft,
                  child: IgnorePointer(
                    ignoring: _isVisible,
                    child: AnimatedOpacity(
                      opacity: _isVisible ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,color: Colors.white),
                            onPressed: (){
                              Navigator.pop(context);
                            },
                          ),
                          Expanded(
                            child: Text(
                              widget.fileName,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
              ),
              Align(
                  alignment: Alignment.bottomRight,
                  child: IgnorePointer(
                    ignoring: _isVisible,
                    child: AnimatedOpacity(
                      opacity: _isVisible ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.white,size: 28),
                            onPressed: () async {
                              //ローディング
                              Loading.show(message: 'ダウンロード中...', isDismissOnTap: false);

                              var date = DateTime.now();
                              var dtFormat = DateFormat('yyyyMMddHHiiss');
                              String strDate = dtFormat.format(date);
                              final fileName = '$strDate${path.extension(widget.fileName)}';

                              final tempDir = await getTemporaryDirectory();
                              final filePath = '${tempDir.path}/$fileName';
                              await Dio().download(widget.url, filePath);

                              var result = await GallerySaver.saveImage(filePath,albumName: 'CONAVI');

                              print(result);
                              if(result != null && result){
                                Loading.dismiss();
                              }else{
                                Loading.error(message: 'ダウンロードに失敗しました');
                              }
                            },
                          ),
                          // ※左に90度回転するので廃止
                          // IconButton(
                          //   icon: const Icon(Icons.download, color: Colors.white,size: 28),
                          //   onPressed: () async {
                          //     //ローディング
                          //     Loading.show(message: 'ダウンロード中...', isDismissOnTap: false);
                          //     final http.Response response = await http.get(Uri.parse(widget.url));
                          //     final result = await ImageGallerySaver.saveImage(response.bodyBytes);
                          //     print(result);
                          //     if(result['isSuccess'] != null && result['isSuccess']){
                          //       Loading.dismiss();
                          //     }else{
                          //       Loading.error(message: 'ダウンロードに失敗しました');
                          //     }
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
