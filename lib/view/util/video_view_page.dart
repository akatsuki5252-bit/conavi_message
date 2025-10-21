import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:video_player/video_player.dart';

class VideoViewPage extends ConsumerStatefulWidget {
  final String url;
  final String fileName;
  const VideoViewPage(this.url,this.fileName,{Key? key}) : super(key: key);

  @override
  ConsumerState<VideoViewPage> createState() => _VideoViewPageState();
}

class _VideoViewPageState extends ConsumerState<VideoViewPage>{
  //late VideoPlayerController _controller;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    /*_controller = VideoPlayerController.network(widget.url)
      ..addListener(() {
        if(mounted) setState(() {});
      })
      //..setVolume(100.0)
      ..setLooping(false)
      ..initialize().then((value) => _controller.play());*/
  }

  @override
  void dispose() {
    //_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        setState(() {
          _isVisible = !_isVisible; //値を反転
        });
      },
      behavior: HitTestBehavior.opaque, //子要素のタップイベントを邪魔しない
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    // child: AspectRatio(
                    //   aspectRatio: _controller.value.aspectRatio,
                    //   child: Stack(
                    //     alignment: Alignment.bottomCenter,
                    //     children: <Widget>[
                    //       //VideoPlayer(_controller),
                    //       //ClosedCaption(text: _controller.value.caption.text),
                    //       //_ControlsOverlay(controller: _controller),
                    //       // AnimatedSwitcher(
                    //       //   duration: const Duration(milliseconds: 50),
                    //       //   reverseDuration: const Duration(milliseconds: 200),
                    //       //   child: _controller.value.isPlaying
                    //       //       ? const SizedBox.shrink()
                    //       //       : Container(
                    //       //     color: Colors.black26,
                    //       //     child: const Center(
                    //       //       child: Icon(
                    //       //         Icons.play_arrow,
                    //       //         color: Colors.white,
                    //       //         size: 100.0,
                    //       //         semanticLabel: 'Play',
                    //       //       ),
                    //       //     ),
                    //       //   ),
                    //       // ),
                    //       GestureDetector(
                    //         onTap: () {
                    //           //_controller.value.isPlaying ? _controller.pause() : _controller.play();
                    //           //_controller.setVolume(1.0);
                    //         },
                    //       ),
                    //       //VideoProgressIndicator(_controller, allowScrubbing: false),
                    //     ],
                    //   ),
                    // ),
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
                              Navigator.pop(context,true);
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
              // Align(
              //     alignment: Alignment.bottomRight,
              //     child: IgnorePointer(
              //       ignoring: _isVisible,
              //       child: AnimatedOpacity(
              //         opacity: _isVisible ? 0.0 : 1.0,
              //         duration: const Duration(milliseconds: 200),
              //         child: Row(
              //           mainAxisAlignment: MainAxisAlignment.end,
              //           children: [
              //             IconButton(
              //               icon: const Icon(Icons.download, color: Colors.blue,size: 28),
              //               onPressed: () async {
              //
              //                 //ローディング
              //                 EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
              //                 EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
              //                 EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
              //                 await EasyLoading.show(
              //                   status: 'ダウンロード中...',
              //                   dismissOnTap: false,
              //                   maskType: EasyLoadingMaskType.black,
              //                 );
              //
              //                 var date = DateTime.now();
              //                 var dtFormat = DateFormat("yyyyMMddHHiiss");
              //                 String strDate = dtFormat.format(date);
              //                 final fileName = '$strDate${path.extension(widget.videoView.fileName)}';
              //
              //                 final tempDir = await getTemporaryDirectory();
              //                 final filePath = '${tempDir.path}/$fileName';
              //                 await Dio().download(widget.videoView.url, filePath);
              //                 var result = await GallerySaver.saveImage(filePath,albumName: 'CONAVI');
              //
              //                 // final tempDir = await getTemporaryDirectory();
              //                 // final filePath = '${tempDir.path}/$fileName';
              //                 // await Dio().download(widget.imageUrl, filePath);
              //                 // final result = await ImageGallerySaver.saveFile(filePath);
              //
              //                 print(result);
              //                 if(result != null && result){
              //                   EasyLoading.dismiss();
              //                 }else{
              //                   EasyLoading.showError(
              //                     'ダウンロードに失敗しました',
              //                     dismissOnTap: true,
              //                     maskType: EasyLoadingMaskType.black,
              //                   );
              //                 }
              //               },
              //             ),
              //             IconButton(
              //               icon: const Icon(Icons.download, color: Colors.white,size: 28),
              //               onPressed: () async {
              //
              //                 //ローディング
              //                 EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
              //                 EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
              //                 EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
              //                 await EasyLoading.show(
              //                   status: 'ダウンロード中...',
              //                   dismissOnTap: false,
              //                   maskType: EasyLoadingMaskType.black,
              //                 );
              //                 final http.Response response = await http.get(Uri.parse(widget.videoView.url));
              //                 final result = await ImageGallerySaver.saveImage(response.bodyBytes);
              //                 print(result);
              //                 if(result['isSuccess'] != null && result['isSuccess']){
              //                   EasyLoading.dismiss();
              //                 }else{
              //                   EasyLoading.showError(
              //                     'ダウンロードに失敗しました',
              //                     dismissOnTap: true,
              //                     maskType: EasyLoadingMaskType.black,
              //                   );
              //                 }
              //               },
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
