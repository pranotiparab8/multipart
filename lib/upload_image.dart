import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({Key? key}) : super(key: key);

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  List<Asset> imagesList = <Asset>[];
  List<File> compressedImages = [];
  String _error = 'No Error Dectected';

  bool showSpinner = false;
  @override
  void initState() {
    super.initState();
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(imagesList.length, (index) {
        Asset asset = imagesList[index];
        return AssetThumb(
          asset: asset,
          width: 300,
          height: 300,
        );
      }),
    );
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = <Asset>[];
    String error = 'No Error Detected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        selectedAssets: imagesList,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "Example App",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      imagesList = resultList;
      _error = error;
    });

    if (imagesList.isNotEmpty) {
      await compressImages();
    }

    print("Image selected");
  }

  Future<void> compressImages() async {
    for (var image in imagesList) {
      ByteData byteData = await image.getByteData(quality: 100);
      Uint8List imageData = byteData.buffer.asUint8List();

      var compressedImage = await FlutterImageCompress.compressWithList(
        imageData,
        quality: 70, // Adjust the quality as per your requirements
      );

      var tempDir = await getTemporaryDirectory();
      var compressedFile = File('${tempDir.path}/${image.name}');
      await compressedFile.writeAsBytes(compressedImage);

      int sizeInBytes = compressedImage.lengthInBytes;
      double sizeInKilobytes = sizeInBytes / 1024;
      double sizeInMegabytes = sizeInKilobytes / 1024;

      print('Size in bytes: $sizeInBytes');
      print('Size in kilobytes: $sizeInKilobytes');
      print('Size in megabytes: $sizeInMegabytes');
      setState(() {
        compressedImages.add(compressedFile);
      });
    }
  }

  //XFile? imagesList;

  // Future getImage() async {
  //   final pickedFile =
  //       await ImagePicker().pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     image = XFile(pickedFile!.path);
  //     setState(() {});
  //   } else {
  //     print('no image seleected');
  //   }
  // }

  Future<void> uploadImage() async {
    // var stream = new http.ByteStream(image!.openRead());
    // stream.cast();
    try {
      setState(() {
        showSpinner = true;
      });

      var length = await compressedImages!.length;
      print("length $length");
      var uri = Uri.parse(
          'http://121.240.30.232:3702/ImageApi/Api/DocumentUpload/MediaUpload');
      http.MultipartRequest request = new http.MultipartRequest('POST', uri);

      //request.fields['title'] = "Static title";
      // var multiport = new http.MultipartFile('image', stream, length);
      for (int i = 0; i < compressedImages.length; i++) {
        print(compressedImages[i].path);
        // var path1 = await LecleFlutterAbsolutePath.getAbsolutePath(
        //     uri: compressedImages[i].path); //imagesList[i].identifier!
        // XFile imageFile = XFile(path1!);
        request.files.add(await http.MultipartFile.fromPath(
            "rohan_image", compressedImages[i].path));
      }
      var response = await request.send();
      print(response.statusCode);
      if (response.statusCode == 200) {
        setState(() {
          showSpinner = false;
        });
        print(response.statusCode);
        print('image uploaded');
      } else {
        setState(() {
          showSpinner = false;
        });
        print('failed');
      }
    } catch (e) {
      setState(() {
        showSpinner = false;
      });
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Upload Image'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Center(child: Text('Error: $_error')),
              ElevatedButton(
                child: Text("Pick images"),
                onPressed: loadAssets,
              ),
              Expanded(
                child: buildGridView(),
              ),
              Visibility(
                visible: imagesList.isEmpty ? false : true,
                child: ElevatedButton(
                  child: Text("Upload"),
                  onPressed: () async {
                    uploadImage();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
