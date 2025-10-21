import 'package:flutter_easyloading/flutter_easyloading.dart';

class Loading {

  static Future show({
      required String message,
      required bool isDismissOnTap
      }) async{
    EasyLoading.instance.fontSize = 14.0;
    EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
    EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
    EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
    await EasyLoading.show(
      status: message,
      dismissOnTap: isDismissOnTap,
      maskType: EasyLoadingMaskType.black,
    );
  }

  static void error({required String message}){
    EasyLoading.instance.fontSize = 14.0;
    EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
    EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
    EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
    EasyLoading.showError(
      message,
      dismissOnTap: true,
      maskType: EasyLoadingMaskType.black,
    );
  }

  static void dismiss(){
    EasyLoading.dismiss();
  }
}