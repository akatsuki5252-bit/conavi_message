import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:conavi_message/model/group_message.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/view/util/image_view_page.dart';
import 'package:conavi_message/view/util/pdf_view_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;

class WidgetUtils {

  static InputDecoration inputDecoration({
    required IconData? icon,
    required String hintTxt,
    required Color color,
    bool isSuffix = false,
    bool isObscure = false,
    Function? actionSuffix,
  }){
    return InputDecoration(
      contentPadding: const EdgeInsets.all(12),
      fillColor: Colors.white,//背景色
      filled: true,
      prefixIcon: icon != null ? Icon(icon,color: color,size: 24) : null,
      hintText: hintTxt,
      labelStyle: TextStyle(
        fontSize: 12,
        color: color,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 12,
        color: color,
      ),
      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: color,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          width: 2,
          color: color,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: Colors.red,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: color,
        ),
      ),
      suffixIcon: isSuffix ? IconButton(
        icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, size: 24),
        color: color,
        onPressed: () {
          if (actionSuffix != null) actionSuffix();
        },
      ) : null,
      isDense: true,
    );
  }

  static Widget getCircleAvatar(String? imagePath) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey,
      child: imagePath != null && imagePath.isNotEmpty ? ClipOval(
        child: Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (c, o, s) {
            print('error-image:$imagePath');
            return const Icon(Icons.person, size: 35, color: Colors.white);
          },
        ),
      ) : const Icon(Icons.person, size: 35, color: Colors.white)
    );
  }

  static Widget textWithUrl(String text,Color color,double textSize){
    /// URL検知の正規表現で、テキストがURLを含むか確認
    final urlRegExp = RegExp(r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?');
    final urlMatches = urlRegExp.allMatches(text);
    /// URLが含まれていない場合はそのままのText, 含まれている場合はRichTextを返す
    if (urlMatches.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(color: color,fontSize: textSize),
      );
    }else{
      /// 返り値としてのTextSpanのリスト
      final textSpanList = <TextSpan>[];
      var remainingText = text;
      for (final regExpMatch in urlMatches) {
        final url = text.substring(regExpMatch.start, regExpMatch.end);
        final index = remainingText.indexOf(url);

        /// 文字列の初めがURLでない場合は通常のテキストとして生成し、文字列を分割
        if (index != 0) {
          textSpanList.add(normalTextSpan(remainingText.substring(0, index)));
          remainingText = remainingText.substring(index);
        }

        /// URL文字列をハイパーリンクとして生成、文字列を分割して次のループに入る
        textSpanList.add(urlTextSpan(remainingText.substring(0, url.length),textSize));
        remainingText = remainingText.substring(url.length);
      }

      /// 文字列の最後がURLでない場合はremainingTextに残るので、通常のテキストとして生成
      if (remainingText.isNotEmpty) {
        textSpanList.add(normalTextSpan(remainingText));
      }

      return RichText(
        text: TextSpan(
            children: textSpanList
        ),
      );
    }
  }

  static TextSpan urlTextSpan(String text,double textSize) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: textSize,
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          launchUrl(Uri.parse(text), mode: LaunchMode.externalApplication);
        },
    );
  }

  static TextSpan normalTextSpan(String text) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black,
      ),
    );
  }

  static Widget? widgetMessage(
    Auth myAccount,
    BuildContext context,
    GroupMessage message){
    //ユーザーメッセージ
    if(message.type == '1') {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          children: [
            //相手メンバーアイコン
            Visibility(
              visible: message.isMe == false,
              child: Container(
                width: 35,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(right: 0),
                child:CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  foregroundImage: message.member!.imagePath.isNotEmpty
                      ? NetworkImage('${myAccount.domain.url}/api/upload/file.php?member_id=${message.member!.id}&app_token=${myAccount.member.appToken}')
                      : null,
                  child: message.member!.imagePath.isEmpty
                      ? const Icon(Icons.person,size: 35, color: Colors.white)
                      : null,
                ),
              ),
            ),
            //メッセージ
            Column(
              crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: message.isMe ? 0 : 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Visibility(
                            visible: message.isMe == false,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(message.member!.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              showMessage(context,message),
                              //既読・時間（相手）
                              Visibility(
                                visible: !message.isMe,
                                child: Text(intl.DateFormat('HH:mm').format(message.sendTime),style: const TextStyle(fontSize: 11, color: Colors.black)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    //既読・時間（自分）
                    Visibility(
                      visible: message.isMe,
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Visibility(
                              visible: message.isMe && 0 < message.readCount,
                              child: Text(
                                1 < message.readCount ? '既読${message.readCount}' : '既読',
                                style: const TextStyle(fontSize: 11, color: Colors.black),
                              )
                            ),
                            Text(intl.DateFormat('HH:mm').format(message.sendTime),style: const TextStyle(fontSize: 11, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }else if(message.type == '2') { //システムメッセージ
      //print(message.sendTime.minute);
      String sendTime = intl.DateFormat('HH:mm').format(message.sendTime);
      return Center(
        child: Bubble(
          padding: const BubbleEdges.only(top: 4,bottom: 4),
          color: const Color(0xffb8b8b8),
          radius: const Radius.circular(15),
          nip: BubbleNip.no,
          child: Container(
            color: const Color(0xffb8b8b8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8, //表示可能領域の6割まで横サイズ
              minWidth: 10,
            ),
            child: Column(
              children: [
                Text(sendTime,style: const TextStyle(fontSize: 12,color: Colors.white)),
                WidgetUtils.textWithUrl(message.message, Colors.white,12)
              ],
            ),
          ),
        ),
      );
    }else{
      return null;
    }
  }

  ///メッセージを分類
  static Widget showMessage(BuildContext context,GroupMessage message){
    if(!message.isFile){
      return showBubbleMessage(context, message.message, message.isMe);
    }else {
      if (message.files != null && message.files!.isNotEmpty) {
        return Column(
          children: [
            for(int i=0; i<message.files!.length; i++)...{
              showMessageFile(
                context: context,
                fileUrl: message.files![i].url,
                fileName: message.files![i].name,
                fileExtension: message.files![i].extension,
                isMe: message.isMe,
                isLast: i==(message.files!.length-1) ? true : false,
              )
            }
          ],
        );
      } else {
        return showBubbleMessage(context, message.message, message.isMe);
      }
    }
  }

  ///メッセージコメント
  static Widget showBubbleMessage(BuildContext context,String message,bool isMe){
    return InkWell(
      onLongPress: () async {},
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Bubble(
        color: isMe ? const Color(0xFFFCD997) : const Color(0xFFd1d8e0),
        radius: const Radius.circular(15),
        nip: isMe ? BubbleNip.rightBottom : BubbleNip.leftTop,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            //表示可能領域の6割まで横サイズ
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                minWidth: 10,
              ),
              child: textWithUrl(message, Colors.black,15)
          ),
        ),
      ),
    );
  }

  ///ファイルメッセージ
  static Widget showMessageFile({
    required BuildContext context,
    required String fileUrl,
    required String fileName,
    required String fileExtension,
    required bool isMe,
    required bool isLast}) {
    // print(fileUrl);
    // print(fileName);
    // print(fileExtension.toLowerCase());
    // print(isLast);
    if (fileExtension.toLowerCase() == '.png' ||
        fileExtension.toLowerCase() == '.jpg' ||
        fileExtension.toLowerCase() == '.jpeg' ||
        fileExtension.toLowerCase() == '.gif') {
      //画像
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: 320,
          minHeight: 20.0,
          minWidth: 20.0,
        ),
        padding: isMe == true ? const EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 0) : const EdgeInsets.only(left: 0, right: 5, top: 0, bottom: 0),
        child: Padding(
          padding: isLast != true ? const EdgeInsets.only(bottom: 5) : const EdgeInsets.only(bottom: 0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewPage(fileUrl, fileName),
                ),
              );
            },
            onLongPress: () {
              //if(message.isMe) showMessageOption(myAccount, message);
            },
            child: CachedNetworkImage(
              maxHeightDiskCache: 1000,
              imageUrl: fileUrl,
              placeholder: (context, url) =>
              const CircularProgressIndicator(color: Colors.amber),
              errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.red),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }else if(fileExtension.toLowerCase() == '.pdf'){
      return InkWell(
        onTap: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => PdfViewPage(fileUrl, fileName)),
          );
        },
        child: IgnorePointer(
          child: Container(
              width: 320,
              height: 320,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                maxHeight: 320,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 0),
              child: const PDF(
                swipeHorizontal: false,
                defaultPage: 0,
                // pageFling: true,
                // fitEachPage: true,
                // pageSnap: true,
                // preventLinkNavigation: true
              ).cachedFromUrl(
                fileUrl,
                placeholder: (progress) => const CircularProgressIndicator(color: Colors.amber),
                errorWidget: (error) => const Icon(Icons.error, color: Colors.red),
              )
          ),
        ),
      );
    }else{
      return Bubble(
        margin: const BubbleEdges.only(top: 10),
        color: isMe ? const Color(0xFFFCD997) : const Color(0xFFd1d8e0),
        radius: const Radius.circular(15),
        nip: isMe ? BubbleNip.rightBottom : BubbleNip.leftTop,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          //表示可能領域の6割まで横サイズ
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
            minWidth: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 2),
                child: Icon(Icons.description_outlined),
              ),
              Flexible(
                // child: Text(
                //   file.name,
                //   textAlign: TextAlign.start,
                //   style: TextStyle(
                //       fontSize: 15,
                //       color: isMe ? Colors.black : Colors.black),
                // ),
                child: RichText(
                    text: TextSpan(
                    text: fileName,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        try {
                          final uri = Uri.parse(fileUrl);
                          if (await canLaunchUrl(uri)) {
                             await launchUrl(uri,mode: LaunchMode.externalApplication);
                           } else {
                             print('Could not launch $uri');
                           }
                        } catch (e) {
                          print('error url_launch:$e');
                        }
                      },
                  )
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
