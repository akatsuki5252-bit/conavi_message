import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.contentWidget,
    this.cancelActionText,
    this.cancelAction,
    required this.defaultActionText,
    this.action,
  });

  final String title;
  final Widget contentWidget;
  final String? cancelActionText;
  final Function? cancelAction;
  final String defaultActionText;
  final Function? action;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.only(left: 15,top: 15,bottom:15,right: 15),
      actionsPadding: const EdgeInsets.only(top: 0,bottom: 5,right: 10),
      title: title != '' ? Container(
        color: const Color(0xfff8b500),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(top:10,left: 15,bottom: 10,right: 10),
        child: Text(
          title, style: const TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold),
        ),
      ) : null,
      content: contentWidget,
      actions: [
        if (cancelActionText != null)
          // TextButton(
          //   child: Text(cancelActionText!,style: const TextStyle(color: Colors.black)),
          //   onPressed: () {
          //     if (cancelAction != null) cancelAction!();
          //     Navigator.of(context).pop(false);
          //   },
          // ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onPressed: () {
              if (cancelAction != null) cancelAction!();
              Navigator.of(context).pop(false);
            },
            child: Text(cancelActionText!,style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
          ),
        // TextButton(
        //   child: Text(defaultActionText,style: const TextStyle(color: Colors.black,backgroundColor: Colors.red)),
        //   onPressed: () {
        //     if (action != null) action!();
        //     Navigator.of(context).pop(true);
        //   },
        // ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff3166f7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          onPressed: () {
            if (action != null) action!();
            Navigator.of(context).pop(true);
          },
          child: Text(defaultActionText,style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        ),
      ],
    );
  }
}
