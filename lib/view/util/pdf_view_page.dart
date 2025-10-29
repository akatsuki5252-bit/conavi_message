import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfViewPage extends ConsumerStatefulWidget {
  final String url;
  final String fileName;
  const PdfViewPage(this.url,this.fileName,{Key? key}) : super(key: key);

  @override
  ConsumerState<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends ConsumerState<PdfViewPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.download,color: Colors.blue),
          //   onPressed: () async{
          //     //ローディング
          //     EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
          //     EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
          //     EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
          //     await EasyLoading.show(
          //       status: 'ダウンロード中...',
          //       dismissOnTap: false,
          //       maskType: EasyLoadingMaskType.black,
          //     );
          //
          //     var date = DateTime.now();
          //     var dtFormat = DateFormat("yyyyMMddHHiiss");
          //     String strDate = dtFormat.format(date);
          //     final fileName = '$strDate${path.extension(widget.pdfView.fileName)}';
          //
          //     final tempDir = await getTemporaryDirectory();
          //     final filePath = '${tempDir.path}/$fileName';
          //     await Dio().download(widget.pdfView.url, filePath);
          //     var result = await GallerySaver.saveImage(filePath,albumName: 'CONAVI');
          //
          //     FunctionUtils.log(result);
          //     if(result != null && result){
          //       EasyLoading.dismiss();
          //     }else{
          //       EasyLoading.showError(
          //         'ダウンロードに失敗しました',
          //         dismissOnTap: true,
          //         maskType: EasyLoadingMaskType.black,
          //       );
          //     }
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.download),
          //   onPressed: () async{
          //     //ローディング
          //     EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
          //     EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
          //     EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
          //     await EasyLoading.show(
          //       status: 'ダウンロード中...',
          //       dismissOnTap: false,
          //       maskType: EasyLoadingMaskType.black,
          //     );
          //     final http.Response response = await http.get(Uri.parse(widget.pdfView.url));
          //     final result = await ImageGallerySaver.saveImage(response.bodyBytes);
          //     FunctionUtils.log(result);
          //     if(result['isSuccess'] != null && result['isSuccess']){
          //       EasyLoading.dismiss();
          //     }else{
          //       EasyLoading.showError(
          //         'ダウンロードに失敗しました',
          //         dismissOnTap: true,
          //         maskType: EasyLoadingMaskType.black,
          //       );
          //     }
          //   },
          // )
        ],
      ),
      body: SafeArea(
        child: const PDF(
          preventLinkNavigation: false,
          pageSnap: true,
          fitEachPage: true,
          pageFling: true,
          nightMode: false,
          swipeHorizontal: false,
          autoSpacing: true,
          enableSwipe: true,
        ).fromUrl(
          widget.url,
          placeholder: (double progress) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
          errorWidget: (dynamic error) => Center(child: Text('PDFを表示できません\n ${error.toString()}')),
        ),
      ),
    );
  }
}
