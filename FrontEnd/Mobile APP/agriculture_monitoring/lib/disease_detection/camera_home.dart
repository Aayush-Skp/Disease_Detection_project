import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:agriculture_monitoring/disease_detection/edit_url.dart';
import 'package:agriculture_monitoring/widgets/app_buttons.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agriculture_monitoring/disease_detection/diseaseProfile.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class MyCamera extends StatefulWidget {
  const MyCamera({super.key});

  @override
  State<MyCamera> createState() => _MyCameraState();
}

class _MyCameraState extends State<MyCamera> {
  void _showLogoutDialog(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> _loadUrls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUrl = prefs.getString('currentUrl') ?? currentUrl;
      sourceUrl = prefs.getString('sourceUrl') ?? sourceUrl;
    });
  }

  Future<void> _saveUrls(String newCurrentUrl, String newSourceUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUrl', newCurrentUrl);
    await prefs.setString('sourceUrl', newSourceUrl);
  }

  bool _isFullScreen = false;
  StreamController<Uint8List>? _streamController;
  bool _isStreaming = false;
  File? image;
  String _response = 'Please Upload an image to get started';
  DiseaseProfile? _diseaseProfile;
  bool _isLoading = false;
  StreamSubscription? _streamSubscription;
  String currentUrl = "10.0.2.2:8000";
  String sourceUrl = '192.168.1.134';
  // final String imageUrlEndpoint = 'http://192.168.1.134/capture';
  // final ImagePicker _picker = ImagePicker();
  //final String streamUrl = 'http://192.168.1.134:81/stream';

  @override
  void initState() {
    super.initState();
    _loadUrls();
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  void _startStream() {
    if (_streamController == null || _streamController!.isClosed) {
      _streamController = StreamController<Uint8List>.broadcast();
      _isStreaming = true;
      _fetchMjpegStream();
    }
  }

  void _stopStream() {
    _isStreaming = false;
    _streamSubscription?.cancel(); // Cancel the subscription here
    _streamController?.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF141514),
      body: Stack(children: [
        Opacity(
          opacity: .8,
          child: Container(
            padding: EdgeInsets.fromLTRB(15, 32, 0, 0),
            child: Column(
              children: [
                const SizedBox(
                  height: 25,
                ),
                Container(
                  width: 50,
                  height: 50,
                  child: ClipOval(
                      child: Image.asset('assets/mulogo.png',
                          width: 185, height: 185, fit: BoxFit.cover)),
                )
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              //Spacer(),
              const SizedBox(height: 40),
              image != null
                  ? Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3C3D37),
                          width: 5.0,
                        ),
                      ),
                      child: ClipOval(
                          child: Image.file(image!,
                              width: 185, height: 185, fit: BoxFit.cover)),
                    )
                  : Image.asset('assets/tomato.png',
                      width: 180, height: 180, fit: BoxFit.fitWidth),
              const SizedBox(height: 15),

              Center(
                child: Text(
                  'AI-Enabled Agricultural Monitoring System',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditPage(
                                  currentUrl: currentUrl,
                                  sourceUrl: sourceUrl)));
                      if (result != null) {
                        setState(() {
                          currentUrl = result['currentUrl'];
                          sourceUrl = result['sourceUrl'];
                        });
                        _saveUrls(currentUrl, sourceUrl);
                      }
                    },
                    child: Text(
                      'Config: $currentUrl',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppButtons(
                  title: 'Crop Status',
                  icon: Icons.add_to_home_screen_outlined,
                  onClicked: _onButtonClicked),
              const SizedBox(height: 15),
              AppButtons(
                  title: 'Monitor Crops',
                  icon: Icons.videocam,
                  onClicked: () =>
                      {_showVideoPlayerDialog(context), _startStream()}),
              const SizedBox(height: 15),
              Row(
                children: [
                  Flexible(
                    child: AppButtons(
                      title: 'Gallery',
                      icon: Icons.image_outlined,
                      onClicked: () => pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: AppButtons(
                        title: 'Camera',
                        icon: Icons.camera_alt_outlined,
                        onClicked: () => pickImage(ImageSource.camera)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                flex: 1,
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: Radius.circular(8),
                  child: SingleChildScrollView(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : (_diseaseProfile != null
                            ? _buildDiseaseProfile()
                            : Text(
                                _response,
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 17,
                                    color: Color(0xFFD9D9D9)),
                              )),
                  ),
                ),
              ),
              // Spacer(),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                child: Opacity(
                  opacity: .3,
                  child: Text(
                    '@Group:KPBE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Container(
                child: Opacity(
                  opacity: .3,
                  child: Text(
                    'Graduate school of Computer Engineering, 2019 Batch',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Container(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 50, 15, 0),
              child: Opacity(
                opacity: .7,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _showLogoutDialog(context),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30.0,
                        textDirection: TextDirection.ltr,
                        semanticLabel: 'Icon',
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        )
      ]),
    );
  }

  Future pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;
      final imageTemporary = File(image.path);
      _uploadFile(imageTemporary);
      setState(() {
        this.image = imageTemporary;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() {
      _response == '';
      _isLoading = true;
      _diseaseProfile = null;
    });

    final url = Uri.parse('http://${currentUrl}/detect');

    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      print('Response body: ${responseData.body}');
      if (response.statusCode == 200) {
        var responseJson = json.decode(responseData.body);
        if (responseJson is Map<String, dynamic> &&
            responseJson.containsKey('prediction')) {
          var predictionJson = responseJson['prediction'];
          var diseaseProfile = DiseaseProfile.fromJson(predictionJson);
          setState(() {
            _diseaseProfile = diseaseProfile;
            _response = '';
            _isLoading = false;
            print(_response);
          });
        } else {
          setState(() {
            _response = 'Invalid response format';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _response =
              'Failed to get prediction. status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error during file upload: $e');
      setState(() {
        _response = 'Error during upload: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildDiseaseProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Name: ${_diseaseProfile!.name}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${((_diseaseProfile!.confidence).toStringAsFixed(2))}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    backgroundColor: _diseaseProfile!.confidence == 1
                        ? Colors.grey
                        : Colors.pink),
              ),
            )
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Severity: ${_diseaseProfile!.severity}',
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 17,
                  color: Colors.white),
            ),
            SizedBox(
              width: 5,
            ),
            Container(
              color: _diseaseProfile!.severity == 'Moderate'
                  ? Colors.yellow
                  : _diseaseProfile!.severity == 'Severe'
                      ? Colors.red
                      : _diseaseProfile!.severity == 'Moderate to Severe'
                          ? Colors.orange
                          : Colors.green,
              height: 20,
              width: 20,
              child: SizedBox(
                width: 20,
                height: 20,
              ),
            )
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Harmfulness: ${_diseaseProfile!.harmfulness}',
          style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 17,
              color: Color(0xFFD9D9D9)),
        ),
        SizedBox(height: 8),
        Text(
          'Prevention:',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        ..._diseaseProfile!.prevention.map((item) => Text(
              '- $item',
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 17,
                  color: Color(0xFFD9D9D9)),
            )),
        SizedBox(height: 8),
        Text(
          'Treatement: ${_diseaseProfile!.treatment}',
          style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 17,
              color: Color(0xFFD9D9D9)),
        ),
        SizedBox(height: 8),
        Text(
          'Pesticide:',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        ..._diseaseProfile!.pesticide.map((item) => Text(
              '- $item',
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 17,
                  color: Color(0xFFD9D9D9)),
            )),
      ],
    );
  }

  Future<File> _fetchImageFromUrl() async {
    try {
      final response = await http.get(Uri.parse('http://${sourceUrl}/capture'));

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        print(imageBytes);

        final directory = await getTemporaryDirectory();

        final filepath = join(directory.path,
            'downloaded_image_${DateTime.now().millisecondsSinceEpoch}.png');

        final file = File(filepath);
        await file.writeAsBytes(imageBytes);

        return file;
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      print('error fetching imaghe: $e');
      throw e;
    }
  }

  Future<void> _onButtonClicked() async {
    try {
      setState(() {
        _isLoading = true;
        _response = 'fetching image.....';
      });
      File imageFile = await _fetchImageFromUrl();

      setState(() {
        this.image = imageFile;
      });
      await _uploadFile(imageFile);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error in the button click : $e");
      setState(() {
        _isLoading = false;
        _response = 'Error: Failed to process the image.';
      });
    }
  }

  void _showVideoPlayerDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: const Color(0xFF3C3D37),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    StreamBuilder<Uint8List>(
                      stream: _streamController?.stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.memory(
                              snapshot.data!,
                              gaplessPlayback: true,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Error loading stream.'),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => _changeFrameRate(14), // Low
                          child: const Text('14Hz'),
                        ),
                        TextButton(
                          onPressed: () => _changeFrameRate(24), // Medium
                          child: const Text('24Hz'),
                        ),
                        TextButton(
                          onPressed: () => _changeFrameRate(30), // High
                          child: const Text('30Hz'),
                        ),
                      ],
                    ),
                    // Resolution Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => _changeResolution(2), // Okay
                          child: const Text('Low-Q'),
                        ),
                        TextButton(
                          onPressed: () => _changeResolution(7), // Medium
                          child: const Text('Medium-Q'),
                        ),
                        TextButton(
                          onPressed: () => _changeResolution(11), // HD
                          child: const Text('High-Q'),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: () {
                              _stopStream();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'close',
                              style: TextStyle(color: Colors.white),
                            )),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleFullScreen(
                                context); // Toggle fullscreen mode
                          },
                          child: Text(
                            'Full Screen',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  Future<void> _fetchMjpegStream() async {
    try {
      final client = http.Client();
      final request =
          http.Request('GET', Uri.parse('http://${sourceUrl}:81/stream'));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType == null ||
            !contentType.contains('multipart/x-mixed-replace')) {
          print('Invalid content-type: $contentType');
          return;
        }

        final boundary = '--' + contentType.split('boundary=')[1];
        final boundaryBytes = ascii.encode(boundary);

        Uint8List buffer = Uint8List(0);
        Uint8List lastValidFrame = Uint8List(0);

        _streamSubscription = response.stream.listen((List<int> chunk) {
          if (!_isStreaming) return;

          buffer = Uint8List.fromList([...buffer, ...chunk]);

          while (true) {
            final boundaryIndex = _indexOf(buffer, boundaryBytes);
            if (boundaryIndex == -1) break;

            final headersEndIndex = _indexOf(buffer, ascii.encode('\r\n\r\n'),
                start: boundaryIndex);
            if (headersEndIndex == -1) break;

            final contentStartIndex = headersEndIndex + 4;

            final nextBoundaryIndex =
                _indexOf(buffer, boundaryBytes, start: contentStartIndex);
            if (nextBoundaryIndex == -1) break;

            final imageBytes =
                buffer.sublist(contentStartIndex, nextBoundaryIndex);

            if (imageBytes.isNotEmpty) {
              lastValidFrame = imageBytes;
              _streamController?.add(lastValidFrame);
            }

            buffer = buffer.sublist(nextBoundaryIndex);
          }
        });
      } else {
        print(
            'Failed to connect to the stream. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching MJPEG stream: $e');
    }
  }

  int _indexOf(Uint8List data, List<int> pattern, {int start = 0}) {
    for (int i = start; i <= data.length - pattern.length; i++) {
      bool found = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  Future<void> _changeFrameRate(int value) async {
    final String url = 'http://${sourceUrl}/control?var=quality&val=$value';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Frame rated change to $value');
      } else {
        print('Failed to change frame rate. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error changing frame rate: $e');
    }
  }

  Future<void> _changeResolution(int value) async {
    final String url = 'http://${sourceUrl}/control?var=framesize&val=$value';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Resolution changed to $value');
      } else {
        print('Failed to change resolution. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error changing resolution: $e');
    }
  }

  void _toggleFullScreen(BuildContext context) {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: StreamBuilder<Uint8List>(
                        stream: _streamController?.stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.memory(
                                snapshot.data!,
                                gaplessPlayback: true,
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error loading stream.'),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Close fullscreen
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
    } else {}
  }
}
