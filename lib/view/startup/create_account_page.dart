// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  static const String routeName = '/createAccountPage';

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController selfIntroductionController = TextEditingController();
  File? _image;
  String _imagePath = '';
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text(
                '新規登録',
                style: TextStyle(color: Colors.black),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        GestureDetector(
                          onTap: () async {
                            var result =
                                await FunctionUtils.getImageFromGallery();
                            if (result != null) {
                              setState(() {
                                _image = File(result.path);
                              });
                            }
                          },
                          child: CircleAvatar(
                            foregroundImage:
                                _image == null ? null : FileImage(_image!),
                            radius: 40,
                            child: const Icon(Icons.add),
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          width: 300,
                          child: TextFormField(
                            controller: emailController,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'メールアドレスを入力してください';
                              } else if (!EmailValidator.validate(value)) {
                                return 'メールアドレスが不正です';
                              }
                              return null;
                            },
                            decoration:
                                const InputDecoration(hintText: 'メールアドレス'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Container(
                            width: 300,
                            child: TextFormField(
                              controller: passController,
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'パスワードを入力してください';
                                }
                                return null;
                              },
                              decoration:
                                  const InputDecoration(hintText: 'パスワード'),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Container(
                            width: 300,
                            child: TextFormField(
                              controller: nameController,
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return '名前を入力してください';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(hintText: '名前'),
                            ),
                          ),
                        ),
                        Container(
                          width: 300,
                          child: TextField(
                            controller: selfIntroductionController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: const InputDecoration(hintText: '自己紹介'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  var myAccount = await createAccount();
                                  if (myAccount is Member) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.blue,
                                        content: Row(
                                          children: const [
                                            Icon(Icons.thumb_up,
                                                color: Colors.white),
                                            SizedBox(width: 20),
                                            Expanded(
                                              child: Text('アカウント作成成功'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );

                                    setState(() {
                                      _isLoading = false;
                                    });

                                    Navigator.pop(context);
                                    /*Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Screen()));*/
                                  } else {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                                /*var result = await Authentication.signUp(
                                    email: emailController.text,
                                    pass: passController.text);
                                if (result is UserCredential) {
                                  var _result = await createAccount(result.user!.uid);
                                  if (_result == true) {
                                    result.user!.sendEmailVerification();
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => CheckEmailPage(
                                                email: emailController.text,
                                                pass: passController.text)));
                                    //Navigator.pop(context);
                                  }
                                }
                              }*/
                              },
                              child: const Text('アカウントを作成')),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<dynamic> createAccount() async {
    if (_image != null) {
      _imagePath = await FunctionUtils.uploadImage(_image!);
    }
    Member newMember = Member(
      id: '',
      email: emailController.text,
      password: passController.text,
      name: nameController.text,
      selfIntroduction: selfIntroductionController.text,
      imagePath: _imagePath,
    );
    var result = await ApiMembers.setMember(newMember);
    return result;
  }
}
