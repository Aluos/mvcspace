import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mvcwallet/bean/Update.dart';
import 'package:mvcwallet/data/Indo.dart';
import 'package:mvcwallet/main.dart';
import 'package:mvcwallet/sqlite/SqWallet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bean/RateResponse.dart';
import '../dialog/MyWalletDialog.dart';
import '../page/SimpleDialog.dart';

Future<void> initVersion() async {
  PackageInfo pack=await PackageInfo.fromPlatform();
  versionCode=pack.buildNumber;
  versionName=pack.version;
}


void doCheckVersion(BuildContext context) async {
  final dio = Dio();
  final response=await dio.post("https://api.show3.space/app-base/v1/app/upgrade/info",data: {'app_name':'metalet','platform':'android'});
  if (response.statusCode == HttpStatus.OK) {
    print(response.data.toString());
    Update update = Update.fromJson(response.data);
    print("object:"+update.data!.url!);
    if(update.data!.versionCode!>int.parse(versionCode)){
      // ignore: use_build_context_synchronously
      showDialog(context: context, builder: (context){
        return  CheckVersionDialog(url: update.data!.url!);
      });
    }
  }
}





Future<void> launchUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
  }
  // if (!await launchUrl(Uri.parse(url))) {
  //   throw Exception('Could not launch $url');
  // }
}


final LocalAuthentication _localAuthentication = LocalAuthentication();

Future<bool> authenticateMe() async {
  // 8. 此方法会打开一个指纹验证对话框。
  //    我们不需要创建一个对话框，它可以从设备中自然弹出。
  bool authenticated = false;
  try {
    authenticated = await _localAuthentication.authenticate(
      localizedReason: "Please verify your fingerprints", // 消息对话框
      options: const AuthenticationOptions(  biometricOnly: true,
          useErrorDialogs: true, stickyAuth: true),
    );
    return authenticated;
  } catch (e) {
    print(e);
    return authenticated;
  }
  // if (!mounted) return;
}


void showToast(String content) {
  Fluttertoast.showToast(
      msg: content,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0x80000000),
      textColor: Colors.white,
      fontSize: 16.0);
}

String validateInput(String? input) {
  String resut = "";
  if (input == null) {
    return resut;
  }
  if (input.isEmpty) {
    return resut;
  }
  resut = input;
  return resut;
}

bool isNoEmpty(String? input) {
  if (input == null) {
    return false;
  }
  if (input.isEmpty) {
    return false;
  }
  return true;
}

void changeWalletInfo(Wallet wallet) {
  List changeWalletList = [];
  changeWalletList.add(wallet);
  String cacheWallet = json.encode(changeWalletList);
  SharedPreferencesUtils.setValue("mvc_wallet", cacheWallet);
}

void deleteWallet() {
  myWalletList.clear();
  SharedPreferencesUtils.setValue("mvc_wallet", "");
  myWallet = Wallet("", "", "", "0.0", "0", "Wallet", 0);
  // webViewController.runJavaScript("initMetaWallet('','','','')");
  wallets = "";
  spaceBalance = "0.0 Space";
  walletBalance = "\$ 0.0";
}

void initLocalWallet() {
  SharedPreferencesUtils.getString("mvc_wallet", "")
      .then((value) => print("Wallet： " + value.toString()));
  SharedPreferencesUtils.getString("mvc_wallet", "").then((value) {
    wallets = value;
    SharedPreferencesUtils.getInt("id_key", id).then((value) {
      id = value;
      SharedPreferencesUtils.getInt("selectIndex_key", selectIndex)
          .then((value) {
        selectIndex = value;
        if (wallets.isNotEmpty) {
          myWalletList = json.decode(wallets);
          print(" selectInde$selectIndex");
          print("：" + myWalletList.toString());
          myWallet = Wallet.fromJson(myWalletList[selectIndex]);
          isLogin = true;
          dioRate(myWallet.balance);
        } else {
          print("Wallet Null");
        }
      });
    });
  });

  SharedPreferencesUtils.getBool("isUst_key", true)
      .then((value) => isUst = value);

  Timer.periodic(const Duration(seconds: 1), (timer) {
    timeCount -= 1;
    if (timeCount <= 0) {
      String editMnem = myWallet.mnemonic;
      String mne = myWallet.path;
      var seInt = id.toString();
      if (mne.isNotEmpty) {
        webViewController.runJavaScript(
            "initMetaWallet('$editMnem','$mne','$seInt','${myWallet.name}')");
      }
      timer.cancel();
    }
  });
}

void initLocalWalletBySql() {

  SqWallet sqWallet = SqWallet();
  Future<List<Wallet>> list = sqWallet.getAllWallet();
  list.then((value) {
    if (value.isNotEmpty) {
      print("获取的缓存数据："+value.toString());
      for (var wallet in value) {
        // ignore: unrelated_type_equality_checks
        if(wallet.isChoose==1){
          myWallet = wallet;
          isLogin = true;
          dioRate(myWallet.balance);
        }
      }
    } else {
      print("Wallet Null");
    }
  });
  
  


  SharedPreferencesUtils.getBool("isUst_key", true)
      .then((value) => isUst = value);

  Timer.periodic(const Duration(seconds: 1), (timer) {
    timeCount -= 1;
    if (timeCount <= 0) {
      String editMnem = myWallet.mnemonic;
      String mne = myWallet.path;
      var seInt = id.toString();
      if (mne.isNotEmpty) {
        webViewController.runJavaScript(
            "initMetaWallet('$editMnem','$mne','$seInt','${myWallet.name}')");
      }
      timer.cancel();
    }
  });
}

void hasNoLogin(Indo indo) {
  // showDialog(
  //     context: navKey.currentState!.overlay!.context,
  //     builder: (context) {
  //       return MyWalletDialog(indo: indo, isVisibility: true);
  //     });
  showDialog(
      // context: navKey.currentState!.overlay!.context,
      // builder: (context) {
      //   return CreateWalletDialog(indo: indo);
      // });
      context: navKey.currentState!.overlay!.context,
      builder: (context) {
        return MyWalletDialog(indo: indo, isVisibility: true);
      });
}

void addMvcWallet(Indo indo) {
  showDialog(
      context: navKey.currentState!.overlay!.context,
      builder: (context) {
        return MyWalletDialog(indo: indo, isVisibility: true);
      });
}

class SharedPreferencesUtils {
  static void setValue(String key, Object? value) {
    if (value is int) {
      setInt(key, value);
    } else if (value is bool) {
      setBool(key, value);
    } else if (value is double) {
      setDouble(key, value);
    } else if (value is String) {
      setString(key, value);
    } else if (value is List<String>) {
      setStringList(key, value);
    }
  }

  static Future getValue<T>(String key, T defaultValue) async {
    if (defaultValue is int) {
      return getInt(key, defaultValue);
    } else if (defaultValue is double) {
      return getDouble(key, defaultValue);
    } else if (defaultValue is bool) {
      return getBool(key, defaultValue);
    } else if (defaultValue is String) {
      return getString(key, defaultValue);
    } else if (defaultValue is List<String>) {
      return getStringList(key);
    }
  }

  static void setInt(String key, int? value, [int defaultValue = 0]) async {
    var sp = await SharedPreferences.getInstance();
    sp.setInt(key, value ?? defaultValue);
  }

  static Future<int> getInt(String key, [int defaultValue = 0]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getInt(key) ?? defaultValue;
  }

  static Future<bool> setBool(String key, bool? value,
      [bool defaultValue = false]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.setBool(key, value ?? defaultValue);
  }

  static Future<bool> getBool(String key, [bool defaultValue = false]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getBool(key) ?? defaultValue;
  }

  static Future<bool> setDouble(String key, double? value,
      [double defaultValue = 0.0]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.setDouble(key, value ?? defaultValue);
  }

  static Future<double> getDouble(String key,
      [double defaultValue = 0.0]) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getDouble(key) ?? defaultValue;
  }

  static Future<bool> setString(String key, String? value,
      [String defaultValue = '']) async {
    var sp = await SharedPreferences.getInstance();
    return sp.setString(key, value ?? defaultValue);
  }

  static Future<String> getString(String key,
      [String defaultValue = 'false']) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getString(key) ?? defaultValue;
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    var sp = await SharedPreferences.getInstance();
    return sp.setStringList(key, value);
  }

  static Future<List<String>> getStringList(String key) async {
    var sp = await SharedPreferences.getInstance();
    return sp.getStringList(key) ?? List.empty();
  }

  static Future<bool> remove(String key) async {
    var sp = await SharedPreferences.getInstance();
    return sp.remove(key);
  }

  static Future<bool> clearAll() async {
    var sp = await SharedPreferences.getInstance();
    return sp.clear();
  }

  static Future<Set<String>> getKeys() async {
    var sp = await SharedPreferences.getInstance();
    return sp.getKeys();
  }

  static Future<bool> containsKey(String key) async {
    var sp = await SharedPreferences.getInstance();
    return sp.containsKey(key);
  }
}

class Wallet {
  String id = "0";
  String name = "Wallet";
  String mnemonic = "";

  // String path = "m/44'/10001'/0'";
  String path = "10001";
  String address = "";
  String balance = "0.0";
  int isChoose = 0;

  Wallet(this.mnemonic, this.path, this.address, this.balance, this.id,
      this.name, this.isChoose);

  // Map toJson() {
  //   Map map = {};
  //   map["mnemonic"] = mnemonic;
  //   map["path"] = path;
  //   map["address"] = address;
  //   map["balance"] = balance;
  //   map["id"] = id;
  //   map["name"] = name;
  //   map["isChoose"] = isChoose;
  //   return map;
  // }

  Map<String, Object?> toJson() {
    Map<String, Object?>  map = {};
    map["mnemonic"] = mnemonic;
    map["path"] = path;
    map["address"] = address;
    map["balance"] = balance;
    map["id"] = id;
    map["name"] = name;
    map["isChoose"] = isChoose;
    return map;
  }



  factory Wallet.fromJson(Map<String, dynamic> parsedJson) {
    Wallet wallet = Wallet(
        parsedJson['mnemonic'],
        parsedJson['path'],
        parsedJson['address'],
        parsedJson['balance'],
        parsedJson['id'],
        parsedJson['name'],
        parsedJson['isChoose']);
    return wallet;
  }

  @override
  String toString() {
    return 'Wallet{id: $id, name: $name, mnemonic: $mnemonic, path: $path, address: $address, balance: $balance, isChoose: $isChoose}';
  }
}
