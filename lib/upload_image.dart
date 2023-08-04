import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:multipart/model.dart';
import 'package:path_provider/path_provider.dart';

import 'comModel.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({Key? key}) : super(key: key);

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  String imageSize = 'Calculating...';

  List<Asset> imagesList = <Asset>[];
  List<Asset> resultList = <Asset>[];
  List<RandomData> myImagesList = <RandomData>[];
  List<CompRandomData> myComImagesList = <CompRandomData>[];
  List<File> compressedImages = [];

  String _error = 'No Error Dectected';
  double imageSizekb = 0.0;
  bool showSpinner = false;

  @override
  void initState() {
    super.initState();
  }

  Widget buildInfoListView() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: resultList.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          {
            var img = resultList[index]!;
            var imgName = resultList[index].name!;
            var width1 = resultList[index].originalWidth!;
            var height1 = resultList[index].originalHeight!;
            return FutureBuilder<ByteData>(
              future: img.getByteData(),
              builder: (context, snapshot) {
                // if (snapshot.connectionState ==
                //     ConnectionState.waiting) {
                //   return CircularProgressIndicator(); // Show a loader while waiting for image data
                // }

                // if (!snapshot.hasData) {
                //   return Text(
                //       'Image data not available'); // Handle the case when image data is not available
                // }

                ByteData? byteData = snapshot.data;
                if (byteData == null) {
                  return Text(
                      'Image data not available'); // Handle the case when image data is null
                }
                imageSizekb = (byteData.lengthInBytes) / 1024;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: [
                    AssetThumb(
                      asset: img,
                      width: 50,
                      height: 50,
                    ),
                    Text('Image Size: $imageSizekb'),
                    Text("$imgName "),
                    Text("Height: $height1"),
                    Text("Width: $width1"),
                  ]),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget buildInfoListView1() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: myImagesList.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          {
            return Column(children: [
              AssetThumb(
                asset: myImagesList[index].img,
                width: 50,
                height: 50,
              ),
              Text('Image Size: ${myImagesList[index].size}'),
              Text("Height: ${myImagesList[index].height}"),
              Text("Width: ${myImagesList[index].width}"),
            ]);
          }
        },
      ),
    );
  }

  Widget buildListView1() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: myComImagesList.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          {
            return Column(children: [
              Container(
                width: 50,
                height: 50,
                child: myComImagesList[index].img,
              ),
              Text('Image Size: ${myComImagesList[index].size}'),
              Text("Height: ${myComImagesList[index].height}"),
              Text("Width: ${myComImagesList[index].width}"),
            ]);
          }
        },
      ),
    );
  }

  Widget buildListView() {
    print("compressedImageList ${compressedImages.length}");

    return compressedImages.isNotEmpty
        ? ListView.builder(
            itemCount: compressedImages.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      child: Image.file(compressedImages[index],
                          height: 50, width: 50),
                    ),
                    FutureBuilder<Size>(
                      future: getImageDimensions(compressedImages[index]),
                      builder:
                          (BuildContext context, AsyncSnapshot<Size> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          Size imageSize = snapshot.data!;
                          return Column(
                            children: [
                              Text(
                                  "Size: ${compressedImages[index].absolute.readAsBytesSync().lengthInBytes / 1024}"),
                              Text("Height: ${imageSize.height}"),
                              Text("Width: ${imageSize.width}"),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          )
        : Container();
  }

  Future<void> loadAssets() async {
    String error = 'No Error Detected';
    print("pick image");
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

      print("Image selected");

      // imagesList = resultList;
      // _error = error;

      /* for (var index = 0; index < resultList.length; index++) {
        //resultList.forEach((element) async {
        var bytedata = await resultList[index].getByteData();
        Uint8List imageData = await bytedata.buffer.asUint8List();
        int sizeInBytes1 = imageData.lengthInBytes;
        double sizeInKilobytes1 = sizeInBytes1 / 1024;
        double sizeInMegabytes1 = sizeInKilobytes1 / 1024;
        dynamic size4;
        if (sizeInKilobytes1 <= 1024) {
          size4 = "${sizeInKilobytes1.toStringAsFixed(2)} KB";
        } else {
          size4 = "${sizeInMegabytes1.toStringAsFixed(2)} MB";
        }
        var randomData = RandomData(
            img: resultList[index],
            height: resultList[index].originalHeight!,
            width: resultList[index].originalWidth!,
            size: size4,
            path: resultList[index].name!);
        myImagesList.add(randomData);
      }*/
      if (compressedImages.isNotEmpty) {
        compressedImages.clear();
      }
      if (resultList.isNotEmpty) {
        compressImages();
      }
      //});
      // setState(() {});
    } on Exception catch (e) {
      error = e.toString();
    }
  }

  Future<void> compressImages() async {
    print("resultlist: ${resultList.length}");
    try {
      for (int index = 0; index < resultList.length; index++) {
        print("index $index");

        print('before compressed');
        print("Name ${resultList[index].name}");
        int height = resultList[index].originalHeight!;
        int width = resultList[index].originalWidth!;
        print("originalHeight $height originalWidth $width");

        ByteData byteData = await resultList[index].getByteData();
        Uint8List imageData = byteData.buffer.asUint8List();
        int sizeInBytes1 = imageData.lengthInBytes;
        double sizeInKilobytes1 = sizeInBytes1 / 1024;
        double sizeInMegabytes1 = sizeInKilobytes1 / 1024;
        print(
            'Size in bytes: $sizeInBytes1 Size in kilobytes: $sizeInKilobytes1 Size in megabytes: $sizeInMegabytes1');

        var compressedImage = await FlutterImageCompress.compressWithList(
            imageData,
            quality: 70,
            minHeight: height,
            minWidth: width,
            format: CompressFormat.jpeg);

        var tempDir = await getTemporaryDirectory();

        File compressedFile =
            await File('${tempDir.path}/${resultList[index].name}');
        print("file $compressedFile");
        await compressedFile.writeAsBytes(compressedImage);

        int sizeInBytes = compressedImage.lengthInBytes;
        double sizeInKilobytes = sizeInBytes / 1024;
        double sizeInMegabytes = sizeInKilobytes / 1024;
        dynamic size3;
        if (sizeInKilobytes <= 1024) {
          size3 = "${sizeInKilobytes.toStringAsFixed(2)} KB";
        } else {
          size3 = "${sizeInMegabytes.toStringAsFixed(2)} MB";
        }
        print('After compressed Image');
        print(
            'Size in bytes: $sizeInBytes Size in kilobytes: $sizeInKilobytes Size in megabytes: $sizeInMegabytes');
        var decodedImage =
            await decodeImageFromList(compressedFile.readAsBytesSync());
        var ACompresspath = compressedFile.path;
        print(
            '\nHeight ${decodedImage.height} \nWidth ${decodedImage.width} \n$ACompresspath');

        compressedImages.add(compressedFile);
        /* print(compressedImages.length);
        for (var index = 0; index < compressedImages.length; index++) {
          var comRandomData = CompRandomData(
            img: Image.file(compressedImages[index], height: 50, width: 50),
            height: decodedImage.height,
            width: decodedImage.width,
            size: size3,
          );
          // if (compressedImages.isNotEmpty) {
          //   compressedImages.clear();
          // }
          myComImagesList.add(comRandomData);
          // setState(() {});
        }*/
      }
    } catch (e) {
      print("e$e");
    }

    setState(() {});
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
    return Scaffold(
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
            //SizedBox(height: 100, child: buildInfoListView1()),
            //SizedBox(height: 150, child: buildListView1()),
            SizedBox(height: 150, child: buildInfoListView()),
            SizedBox(height: 150, child: buildListView()),
            Visibility(
              visible: resultList.isEmpty ? false : true,
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
    );
  }

// Function to get the image dimensions asynchronously
  Future<Size> getImageDimensions(File imageFile) async {
    Completer<Size> completer = Completer();
    Image image = Image.file(imageFile);
    image.image
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ));
    }));
    return completer.future;
  }
}
