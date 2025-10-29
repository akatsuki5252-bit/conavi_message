import 'package:conavi_message/utils/function_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
//*import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
//import 'package:video_player/video_player.dart';

class UploadFile{
  String id;
  String fileUrl;
  String fileName;
  String fileExt;
  bool isImageFlag = false;
  bool isAudioFlag = false;
  bool isPdfFlag = false;
  bool isVideoFlag = false;
  //VideoPlayerController? videoPlayerController;
  //AudioPlayer? audioPlayer;
  final isAudioPlayProvider = StateProvider((ref) => false);
  late final iconAudioPlayerProvider = StateProvider<Icon>((ref){
    bool isAudioPlay = ref.watch(isAudioPlayProvider);
    FunctionUtils.log('iconAudioPlayerProvider:$isAudioPlay');
    if(isAudioPlay){
      return const Icon(Icons.pause);
    }else{
      return const Icon(Icons.play_arrow);
    }
  });



  UploadFile({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    required this.fileExt
  }){
    if(fileExt.toLowerCase() == '.png' ||
        fileExt.toLowerCase() == '.jpg' ||
        fileExt.toLowerCase() == '.jpeg' ||
        fileExt.toLowerCase() == '.gif') {
      isImageFlag = true;
    }
    if(fileExt.toLowerCase() == '.mp3') isAudioFlag = true;
    if(fileExt.toLowerCase() == '.pdf') isPdfFlag = true;
    if(fileExt.toLowerCase() == '.mp4') isVideoFlag = true;
  }

  Future<void> setFile() async{
    // if(isAudioFlag) {
    //   FunctionUtils.log('setAudio:true');
    //   try {
    //     audioPlayer = AudioPlayer();
    //     await audioPlayer!.setUrl(fileUrl);
    //
    //     // //AudioPlayerの状態を取得
    //     // message.file.audioPlayer!.playbackEventStream.listen((event) async{
    //     //   switch(event.processingState) {
    //     //     case ProcessingState.idle:
    //     //       FunctionUtils.log('[id:${message.id}]:ProcessingState.idle');
    //     //       break;
    //     //     case ProcessingState.loading:
    //     //       FunctionUtils.log('[id:${message.id}]:ProcessingState.loading');
    //     //       break;
    //     //     case ProcessingState.buffering:
    //     //       FunctionUtils.log('[id:${message.id}]:ProcessingState.buffering');
    //     //       break;
    //     //     case ProcessingState.ready:
    //     //       FunctionUtils.log('[id:${message.id}]:ProcessingState.ready');
    //     //       break;
    //     //     case ProcessingState.completed:
    //     //       FunctionUtils.log('[id:${message.id}]:ProcessingState.completed');
    //     //       break;
    //     //     default:
    //     //       FunctionUtils.log('[id:${message.id}]:ProcessingState.default');
    //     //       FunctionUtils.log(event.processingState);
    //     //       break;
    //     //   }
    //     // });
    //     // Catching errors at load time
    //   } on PlayerException catch (e) {
    //     // iOS/macOS: maps to NSError.code
    //     // Android: maps to ExoPlayerException.type
    //     // Web: maps to MediaError.code
    //     // Linux/Windows: maps to PlayerErrorCode.index
    //     FunctionUtils.log("Error code: ${e.code}");
    //     // iOS/macOS: maps to NSError.localizedDescription
    //     // Android: maps to ExoPlaybackException.getMessage()
    //     // Web/Linux: a generic message
    //     // Windows: MediaPlayerError.message
    //     FunctionUtils.log("Error message: ${e.message}");
    //   } on PlayerInterruptedException catch (e) {
    //     // This call was interrupted since another audio source was loaded or the
    //     // player was stopped or disposed before this audio source could complete
    //     // loading.
    //     FunctionUtils.log("Connection aborted: ${e.message}");
    //   } catch (e) {
    //     // Fallback for all other errors
    //     FunctionUtils.log('An error occured: $e');
    //   }
    // }else if(isPdfFlag){
    //   // FunctionUtils.log(fileUrl);
    //   // final http.Response response = await http.get(Uri.parse(fileUrl));
    //   // FunctionUtils.log(response.statusCode);
    //   // if (response.statusCode == 200) {
    //   //   FunctionUtils.log('a');
    //   //   pdfController = PdfController(document: PdfDocument.openData(response.bodyBytes));
    //   //   FunctionUtils.log(pdfController);
    //   // }
    // }else if(isVideoFlag){
    //   try {
    //     // videoPlayerController = VideoPlayerController.network(fileUrl)
    //     //   ..addListener(() {})
    //     //   ..setLooping(false)
    //     //   ..initialize()
    //     //       .then((value) => VideoPlayerController.network(fileUrl).play());
    //   }catch(e){
    //     FunctionUtils.log('video error: $e');
    //   }
    // }
  }
}