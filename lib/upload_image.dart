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
  var BCompresspath = '';
  var ACompresspath = '';
  late String imgName;
  List<Asset> imagesList = <Asset>[];
  List<File> compressedImages = [];

  int height = 0;
  int width = 0;
  double sizeInKilobytes1 = 0.0;
  double sizeInKilobytes = 0.0;
  String _error = 'No Error Dectected';
  var image3;
  var img4;

  bool showSpinner = false;
  @override
  void initState() {
    super.initState();
  }

  Widget buildListView() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: List.generate(compressedImages.length, (index) {
        //File asset = compressedImages[index];

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  child: Image.file(compressedImages[index],
                      height: 100, width: 100),
                ),
                Text(
                    "${compressedImages[index].absolute.readAsBytesSync().lengthInBytes / 1024}"),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget buildInfoListView() {
    return ListView(
      children: [
        SizedBox(
          height: 600,
          child: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              // for (var item in imagesList) {
              //RandomData data = item;
              return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(imagesList.length, (index) {
                      var img = imagesList[index]!;
                      imgName = imagesList[index].name!;
                      var width1 = imagesList[index].originalWidth!;
                      var height1 = imagesList[index].originalHeight!;
                      return Column(children: [
                        AssetThumb(
                          asset: img,
                          width: 100,
                          height: 100,
                        ),
                        Text("$imgName"),
                        Text("$height1"),
                        Text("$width1"),
                      ]);
                    }),
                  ));
              //}
            },
          ),
        ),
      ],
    );
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
    for (image3 in imagesList) {
      ByteData byteData = await image3.getByteData(quality: 100);
      Uint8List imageData = byteData.buffer.asUint8List();

      print('before compressed');
      print("Name ${image3.name}");
      final temp = await getTemporaryDirectory();
      BCompresspath = '${temp.path}/${image3.name}';
      print("path $BCompresspath");
      print("identifier ${image3.identifier}");
      height = image3.originalHeight!;
      width = image3.originalWidth!;
      print("originalHeight $height");
      print("originalWidth $width");
      int sizeInBytes1 = imageData.lengthInBytes;
      sizeInKilobytes1 = sizeInBytes1 / 1024;
      double sizeInMegabytes1 = sizeInKilobytes1 / 1024;
      print('Size in bytes: $sizeInBytes1');
      print('Size in kilobytes: $sizeInKilobytes1');
      print('Size in megabytes: $sizeInMegabytes1');

      var compressedImage =
          await FlutterImageCompress.compressWithList(imageData,
              quality: 70, // Adjust the quality as per your requirements
              minHeight: height,
              minWidth: width,
              format: CompressFormat.jpeg);

      var tempDir = await getTemporaryDirectory();
      File compressedFile = File('${tempDir.path}/${image3.name}');
      await compressedFile.writeAsBytes(compressedImage);
      img4 = compressedImage;
      int sizeInBytes = compressedImage.lengthInBytes;
      sizeInKilobytes = sizeInBytes / 1024;
      double sizeInMegabytes = sizeInKilobytes / 1024;
      print('After compressed Image');
      print('Size in bytes: $sizeInBytes');
      print('Size in kilobytes: $sizeInKilobytes');
      print('Size in megabytes: $sizeInMegabytes');

      var decodedImage =
          await decodeImageFromList(compressedFile.readAsBytesSync());
      print('Height ${decodedImage.height}');
      print('Width ${decodedImage.width}');
      ACompresspath = compressedFile.path;
      print(ACompresspath);

      setState(() {
        compressedImages.add(compressedFile);
      });
    }
  }

  Future<void> uploadImage() async {
    try {
      setState(() {
        showSpinner = true;
      });

      var length = await compressedImages!.length;
      print("length $length");
      var uri = Uri.parse(
          'http://121.240.30.232:3702/ImageApi/Api/DocumentUpload/MediaUpload');
      http.MultipartRequest request = new http.MultipartRequest('POST', uri);

      for (int i = 0; i < compressedImages.length; i++) {
        print(compressedImages[i].path);
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
          title: const Text('Upload Image'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Center(child: Text('Error: $_error')),
              ElevatedButton(
                onPressed: loadAssets,
                child: const Text("Pick images"),
              ),

              SizedBox(height: 200, child: buildInfoListView()),
              SizedBox(height: 200, child: buildListView()),
              // Text(
              //     'before compressed \nPath: $BCompresspath \nHeight: $height \nWidth: $width \nKB: $sizeInKilobytes1'),
              // Text(
              //     'After compressed \nPath: $ACompresspath \nHeight: $height \nWidth: $width \nKB: $sizeInKilobytes'),
              Visibility(
                visible: imagesList.isEmpty ? false : true,
                child: ElevatedButton(
                  child: const Text("Upload"),
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
