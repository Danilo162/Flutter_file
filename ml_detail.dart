import 'package:cardstore/models/adresse.dart';
import 'package:cardstore/models/usercard.dart';
import 'package:cardstore/pages/mlkit/ml_home.dart';
import 'package:cardstore/utils/classes.dart';
import 'package:cardstore/utils/constant.dart';
import 'package:cardstore/utils/database_hepler.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:mlkit/mlkit.dart';
import 'package:intl/intl.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class MLDetail extends StatefulWidget {
  final File _file;
  final String _scannerType;

  MLDetail(this._file, this._scannerType);
  @override
  State<StatefulWidget> createState() {
    return _MLDetailState();
  }
}

class _MLDetailState extends State<MLDetail> {
  UserCard userCard;
  var phoneList = new List();
  var db = new DatabaseHelper();

  List _contactTypes = ["Tel", "E-mail", "Fax"];


  FirebaseVisionTextDetector textDetector = FirebaseVisionTextDetector.instance;
  FirebaseVisionBarcodeDetector barcodeDetector =
      FirebaseVisionBarcodeDetector.instance;
  FirebaseVisionLabelDetector labelDetector =
      FirebaseVisionLabelDetector.instance;
  FirebaseVisionFaceDetector faceDetector = FirebaseVisionFaceDetector.instance;
  List<VisionText> _currentTextLabels = <VisionText>[];
  List<VisionBarcode> _currentBarcodeLabels = <VisionBarcode>[];
  List<VisionLabel> _currentLabelLabels = <VisionLabel>[];
  List<VisionFace> _currentFaceLabels = <VisionFace>[];
 List<VisionText> vstd = new List();
  Stream sub;
  StreamSubscription<dynamic> subscription;
  int nbphone = 0;
  List<String> litems = [];
  var textEdConPhone = <TextEditingController>[];
  var textEdConEmail = <TextEditingController>[];
  var textEdConHeader = new TextEditingController();
  TextEditingController contactTFldOne = new TextEditingController();
  TextEditingController contactTFldTwo = new TextEditingController();
  TextEditingController emailTFldTOne = new TextEditingController();
  TextEditingController emailTFldTwo = new TextEditingController();


  @override
  void initState() {
    super.initState();
    sub = new Stream.empty();
    subscription = sub.listen((_) => _getImageSize)..onDone(analyzeLabels);

  }

  void analyzeLabels() async {
    try {
      var currentLabels;
      if (widget._scannerType == TEXT_SCANNER) {
        currentLabels = await textDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentTextLabels = currentLabels;
            if(currentLabels != null){

              var emailList = new List();
              emailList = Utils.createMlValue("email", _currentTextLabels);
              emailList.forEach((emailController)  {
             //   var textEditingController = new TextEditingController(text: filename);
                textEdConEmail.add(new TextEditingController(text: emailController));
              });
              phoneList = Utils.createMlValue("phone", _currentTextLabels);
              phoneList.forEach((phoneController) {
                textEdConPhone.add( new TextEditingController(text: phoneController));
              });

              var headerList = new List();
              headerList = Utils.createMlValue("header", _currentTextLabels);
              String headerText ="" ;
              String headerTextFinale;
              headerList.forEach((filename)  {
                headerText = " $headerText  $filename";
              });

              headerTextFinale = headerText.trim();
              textEdConHeader = new TextEditingController(text: headerTextFinale);

             // emailList.clear();
            }
            this.vstd = currentLabels;
          });
        }
      } else if (widget._scannerType == BARCODE_SCANNER) {
        currentLabels = await barcodeDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentBarcodeLabels = currentLabels;
          });
        }
      } else if (widget._scannerType == LABEL_SCANNER) {
        currentLabels = await labelDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentLabelLabels = currentLabels;
          });
        }
      } else if (widget._scannerType == FACE_SCANNER) {
        currentLabels = await faceDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentFaceLabels = currentLabels;
          });
        }
      }
    } catch (e) {
      print("MyEx: " + e.toString());
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    textEdConEmail.forEach((controller)  {
      controller.dispose();
    });
      textEdConPhone.forEach((controller)  {
      controller.dispose();
    });
    textEdConHeader.dispose();
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(Cst.appName),
          backgroundColor: Colors.deepOrange,
        ),
        body: Column(
          children: <Widget>[
            buildImage(context),
            widget._scannerType == TEXT_SCANNER
                ? buildTextList(_currentTextLabels)
                : widget._scannerType == BARCODE_SCANNER
                ? buildBarcodeList<VisionBarcode>(_currentBarcodeLabels)
                : widget._scannerType == FACE_SCANNER
                ? buildBarcodeList<VisionFace>(_currentFaceLabels)
                : buildBarcodeList<VisionLabel>(_currentLabelLabels)
          ],
        ));
  }

  Widget buildImage(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Container(
        // decoration: Cst.gradiantRedLinaer(),
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/images/whatsappbac.jpg"), fit: BoxFit.cover),
          ),
          height: 150.0,
          child: Center(
            child: widget._file == null
                ? Text('No Image')
                : FutureBuilder<Size>(
              future: _getImageSize(
                  Image.file(widget._file, fit: BoxFit.fitWidth)),
              builder:
                  (BuildContext context, AsyncSnapshot<Size> snapshot) {
                if (snapshot.hasData) {
                  return Container(
                      foregroundDecoration: (widget._scannerType ==
                          TEXT_SCANNER)
                          ? TextDetectDecoration(
                          _currentTextLabels, snapshot.data)
                          : (widget._scannerType == FACE_SCANNER)
                          ? FaceDetectDecoration(
                          _currentFaceLabels, snapshot.data)
                          : (widget._scannerType == BARCODE_SCANNER)
                          ? BarcodeDetectDecoration(
                          _currentBarcodeLabels,
                          snapshot.data)
                          : LabelDetectDecoration(
                          _currentLabelLabels, snapshot.data),
                      child:
                      Image.file(widget._file, fit: BoxFit.fitWidth));
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          )),
    );
  }
  Widget buildBarcodeList<T>(List<T> barcodes) {
    if (barcodes.length == 0) {
      return Expanded(
        flex: 1,
        child: Center(
          child: Text('Nothing detected',
              style: Theme.of(context).textTheme.subhead),
        ),
      );
    }
    return Expanded(
      flex: 1,
      child: Container(
        child: ListView.builder(
            padding: const EdgeInsets.all(1.0),
            itemCount: barcodes.length,
            itemBuilder: (context, i) {
              var text;

              final barcode = barcodes[i];
              switch (widget._scannerType) {
                case BARCODE_SCANNER:
                  VisionBarcode res = barcode as VisionBarcode;
                  text = "Raw Value: ${res.rawValue}";
                  break;
                case FACE_SCANNER:
                  VisionFace res = barcode as VisionFace;
                  text =
                  "Raw Value: ${res.smilingProbability},${res.trackingID}";
                  break;
                case LABEL_SCANNER:
                  VisionLabel res = barcode as VisionLabel;
                  text = "Raw Value: ${res.label}";
                  break;
              }
              return _buildTextRow(text);
            }),
      ),
    );
  }
  Widget buildTextList(List<VisionText> texts) {
    // DANI
    if (texts.length == 0) {
      return Expanded(
          flex: 1,
          child: Center(
            child: Text('No text detected',
                style: Theme.of(context).textTheme.subhead),
          ));
    }
    return Expanded(
      flex: 1,
      child: SingleChildScrollView(
        child:buildTextRow(texts),
      ),
    );
  }
  Widget _buildTextRow(text) {
    return ListTile(
      title: TextFormField(
        initialValue: "$text",
      ),
      dense: true,
    );
  }
  Widget buildTextRow(List<VisionText> texts) {
    return
      Container(decoration: Cst.gradiantSecond(),
          child:
          Stack(
              children: <Widget>[
                Container(
                  //   height: 450,
                  decoration:Cst.gradiantRedLinaer() ,
//         child: RotatedBox(
//           quarterTurns: 4,
//           child: WaveWidget(
//             config: CustomConfig(
//               gradients: [
//                 [Colors.deepPurple, Colors.deepPurple.shade200],
//                 [Colors.indigo.shade200, Colors.purple.shade200],
//               ],
//               durations: [19440, 10800],
//               heightPercentages: [0.20, 0.25],
//               blur: MaskFilter.blur(BlurStyle.solid, 10),
//               gradientBegin: Alignment.bottomLeft,
//               gradientEnd: Alignment.topRight,
//             ),
//             waveAmplitude: 0,
//             size: Size(
//               double.infinity,
//               double.infinity,
//             ),
//           ),
//         ),
                ),
                Container( child: new Column(
                  children: <Widget>[
                    const SizedBox(
                      height: 20.0, ),
                    Text("Informations détectées",style: TextStyle(fontWeight: FontWeight.w500,
                        fontSize: 16.0,color: Colors.white),
                      textAlign: TextAlign.center,),
                    const SizedBox( height: 10.0, ),
                    Container(child: Column(children :<Widget>[buildTextHeader(texts)]) ,),
                    const SizedBox(  height: 5.0, ),
                    Container(child: Column(children: buildTextPhone(texts),),),
                    const SizedBox(  height: 5.0,),
                    Container(child: Column(children:   buildTextEmail(texts),)),
                    const SizedBox(  height: 25.0,),
                    Text("Ajouter d'autre contacts", style: TextStyle(color: Colors.white )),
                    Container(child:  addphone(),),
                    const SizedBox(  height: 5.0,),
                    Text("Ajouter d'autres adresses mails", style: TextStyle(color: Colors.white )),
                    Container(child:  addemail(),),
                    const SizedBox(  height: 5.0,),
                    Container(child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: RaisedButton(
                        textColor: Colors.white,
                        color: Colors.deepOrange,
                        child: Text("Enregistrer",),
                        onPressed: () {
                          addUserCard();
                          //   Utils.showAlertDialog("Phone", textEdConPhone.toString(),context);
//            print("++++data++++++");
//            print(litems.toString());
                        },
                      ),
                    ),)
                  ],
                ),)

              ]));
  }
  // Save data to database
  List<Widget> buildTextEmail(List<VisionText> texts) {
    List<Widget> listWidgetEmail = new List();
    textEdConEmail.forEach((controller)  {
    if(controller.text != null && controller.text.isNotEmpty && controller.text != ""){
      listWidgetEmail.add( Card(
        margin: EdgeInsets.only(left: 30, right:30, top:30),
        elevation: 11,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
        child: TextField(
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.email, color: Colors.black26,),
              suffixIcon: Icon(Icons.check_circle, color: Colors.black26,),
              hintText: "E-mail",
              hintStyle: TextStyle(color: Colors.black26),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(40.0)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
          ),
          controller: controller,
          keyboardType: TextInputType.emailAddress,
        ),
      ));
    }});
    return listWidgetEmail;
  }
  List<Widget> buildTextPhone(List<VisionText> texts) {
    List<Widget> listWidgetPhone = new List();
    textEdConPhone.forEach((controller){
      if(controller.text != null && controller.text.isNotEmpty && controller.text != ""){
      listWidgetPhone.add( Card(
        margin: EdgeInsets.only(left: 30, right:30, top:30),
        elevation: 11,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
        child: TextField(
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.phone, color: Colors.black26,),
              suffixIcon: Icon(Icons.check_circle, color: Colors.black26,),
              hintText: "Contact",
              hintStyle: TextStyle(color: Colors.black26),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(40.0)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
          ),
          controller: controller,
          keyboardType: TextInputType.phone,
        ),
      ));
    }});
    return  listWidgetPhone;
  }
  Widget buildTextHeader(List<VisionText> texts) {
    return Card(
      margin: EdgeInsets.only(left: 20, right:20, top:30),
      elevation: 11,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
      child: TextField(
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.person, color: Colors.black26,),
            suffixIcon: Icon(Icons.check_circle, color: Colors.black26,),
            hintText: "Nom complet",
            hintStyle: TextStyle(color: Colors.black26),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(40.0)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
        ),
        controller:textEdConHeader,
        keyboardType: TextInputType.multiline,
        maxLines: 4,
      ),
    );

  }

  Widget addphone(){
    //  contactOne = new TextEditingController();
    textEdConPhone.add(contactTFldOne);
    textEdConPhone.add(contactTFldTwo);
    return  new Container (
        child: new Column(
          children: <Widget>[ Card(
            margin: EdgeInsets.only(left: 20, right:20, top:30),
            elevation: 11,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
            child: TextField(
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone, color: Colors.black26,),
                  suffixIcon: Icon(Icons.check_circle, color: Colors.black26,),
                  hintText: "Contact",
                  hintStyle: TextStyle(color: Colors.black26),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(40.0)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
              ),
              controller: contactTFldOne,
              keyboardType: TextInputType.phone,
            ),
          ),
          Card(
            margin: EdgeInsets.only(left: 20, right:20, top:30),
            elevation: 11,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
            child: TextField(
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone, color: Colors.black26,),
                  suffixIcon: Icon(Icons.check_circle, color: Colors.black26,),
                  hintText: "Contact",
                  hintStyle: TextStyle(color: Colors.black26),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(40.0)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
              ),
              controller: contactTFldTwo,
              keyboardType: TextInputType.phone,
            ),
          )
          ],
        ));

  }
  Widget addemail(){
    textEdConEmail.add(emailTFldTOne);
    textEdConEmail.add(emailTFldTwo);
    return  new Container (
        child: new Column(
          children: <Widget>[ Card(
            margin: EdgeInsets.only(left: 20, right:20, top:30),
            elevation: 11,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
            child: TextField(
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.black26,),
                  suffixIcon: Icon(Icons.check_circle, color: Colors.black26,),
                  hintText: "E-mail",
                  hintStyle: TextStyle(color: Colors.black26),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(40.0)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
              ),
              controller: emailTFldTOne,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          Card(
            margin: EdgeInsets.only(left: 20, right:20, top:30),
            elevation: 11,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
            child: TextField(
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.black26,),
                  suffixIcon: Icon(Icons.check_circle, color: Colors.black26,),
                  hintText: "E-mail",
                  hintStyle: TextStyle(color: Colors.black26),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(40.0)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
              ),
              controller: emailTFldTwo,
              keyboardType: TextInputType.emailAddress,
            ),
          )
          ],
        ));

  }
  Future<Size> _getImageSize(Image image) {
    Completer<Size> completer = Completer<Size>();
    image.image.resolve(ImageConfiguration()).addListener(
            (ImageInfo info, bool _) => completer.complete(
          ///  Size(info.image.width.toDouble(), info.image.height.toDouble())));
            Size(info.image.width.toDouble(), info.image.height.toDouble())));
    return completer.future;
  }
  Future addUserCard() async {
    int resul,resultel,resulem;
    int em = 0;
    int tel = 0;
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd--MM-yyyy kk:mm').format(now);
    var userCard = new UserCard(textEdConHeader.text,formattedDate,"1","Groupe1",widget._file.path);
    resul =  await db.saveUserCard(userCard);
    var contactList = new List();
    var emailList = new List();

    textEdConPhone.forEach((f){
      if(f.text.isNotEmpty){
        contactList.add(f.text);
      }
    });
    textEdConEmail.forEach((e){
      if(e.text.isNotEmpty){
        emailList.add(e.text);
      }
    });
    contactList = contactList.toSet().toList();
    emailList = emailList.toSet().toList();


    if(resul != 0) {
      if (contactList.length > 0) {
        for (var c = 0; c < contactList.length; c++) {
          var contat = new Adresse(contactList[c], "tel", "1", resul.toString());
          resultel = await db.saveAdresse(contat); // save contact telephonique

          if (resultel != 0) {
            tel++;
          }
        }
      }
      if (emailList.length > 0) {
        for (var k = 0; k < emailList.length; k++) {
          var email = new Adresse(emailList[k], "email", "1", resul.toString());
          resulem = await db.saveAdresse(email); // save contact telephonique
          if (resulem != 0) {
            em++;
          }
        }
      }
      if (em > 0 || tel > 0) {
        Utils.toaster("Enregistrement effectué "+textEdConHeader.text);
        Utils.showAlertDlgAction("Info", "Enregistrement effectué : "
            "contact = " + tel.toString() + " email = " + em.toString(),
            context);
      }
    }
    else{
      Utils.toaster("Echec d'enregistrement veuillez ressayer");
      Utils.showAlertDialog("Info", "Echec d'enregistrement veuillez ressayer ",
          context);
    }

  }

//  Future addUserCard() async {
//    int resul,resultel,resulem;
//    int em = 0;
//    int tel = 0;
//    String date = DateFormat.yMMMd().format(DateTime.now());
//
//    var userCard = new UserCard(textEdConHeader.text,date,"1","Groupe1",widget._file.path);
//    //  resul =  await db.saveUserCard(userCard);
//
//
//    var contactList = new List();
//    var emailList = new List();
//
//    textEdConPhone.forEach((f){
//      if(f.text.isNotEmpty){
//        contactList.add(f.text);
//      }
//    });
//    textEdConEmail.forEach((e){
//      if(e.text.isNotEmpty){
//        emailList.add(e.text);
//      }
//    });
//    contactList = contactList.toSet().toList();
//    emailList = emailList.toSet().toList();
//
//
//    print("+++++++++++++++DEF+++++++++++++++++++");
//    print(contactList.toString());
//    print(emailList.toString());
//
//    if(resul != 0) {
//      if (textEdConPhone.length > 0) {
//        for (var c = 0; c < textEdConPhone.length; c++) {
//          if(textEdConPhone[c].text != null && textEdConPhone[c].text.isNotEmpty &&
//              textEdConPhone[c].text != "") {
//            print("/////VAVALUE/////////");
//            print(textEdConPhone[c].text);
////            var contat = new Adresse(
////                textEdConPhone[c].text, "tel", "1", resul.toString());
////            resultel =
////            await db.saveAdresse(contat); // save contact telephonique
//          }
//          if (resultel != 0) {
//            tel++;
//          }
//        }
//      }
//      if (textEdConEmail.length > 0) {
//        for (var k = 0; k < textEdConEmail.length; k++) {
//          if(textEdConEmail[k].text != " " || textEdConEmail[k].text != null) {
////            var email = new Adresse(
////                textEdConEmail[k].text, "email", "1", resul.toString());
////            resulem = await db.saveAdresse(email); // save contact telephonique
//          }
//          if (resulem != 0) {
//            em++;
//          }
//        }
//      }
//      if (em > 0 || tel > 0) {
//        Utils.toaster("Enregistrement effectué "+textEdConHeader.text);
//        Utils.showAlertDlgAction("Info", "Enregistrement effectué : "
//            "contact = " + tel.toString() + " email = " + em.toString(),
//            context);
//      }
//    }
//    else{
//      Utils.toaster("Echec d'enregistrement veuillez ressayer");
//      Utils.showAlertDialog("Info", "Echec d'enregistrement veuillez ressayer ",
//          context);
//    }
//
//  }

}

/*
  This code uses the example from azihsoyn/flutter_mlkit
  https://github.com/azihsoyn/flutter_mlkit/blob/master/example/lib/main.dart
*/

class BarcodeDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionBarcode> _barcodes;

  BarcodeDetectDecoration(List<VisionBarcode> barcodes, Size originalImageSize)
      : _barcodes = barcodes,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _BarcodeDetectPainter(_barcodes, _originalImageSize);
  }
}
class _BarcodeDetectPainter extends BoxPainter {
  final List<VisionBarcode> _barcodes;
  final Size _originalImageSize;
  _BarcodeDetectPainter(barcodes, originalImageSize)
      : _barcodes = barcodes,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var barcode in _barcodes) {
      final _rect = Rect.fromLTRB(
          offset.dx + barcode.rect.left / _widthRatio,
          offset.dy + barcode.rect.top / _heightRatio,
          offset.dx + barcode.rect.right / _widthRatio,
          offset.dy + barcode.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();
  }
}
class TextDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionText> _texts;
  TextDetectDecoration(List<VisionText> texts, Size originalImageSize)
      : _texts = texts,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _TextDetectPainter(_texts, _originalImageSize);
  }
}
class _TextDetectPainter extends BoxPainter {
  final List<VisionText> _texts;
  final Size _originalImageSize;
  _TextDetectPainter(texts, originalImageSize)
      : _texts = texts,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var text in _texts) {
      final _rect = Rect.fromLTRB(
          offset.dx + text.rect.left / _widthRatio,
          offset.dy + text.rect.top / _heightRatio,
          offset.dx + text.rect.right / _widthRatio,
          offset.dy + text.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();
  }
}
class FaceDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionFace> _faces;
  FaceDetectDecoration(List<VisionFace> faces, Size originalImageSize)
      : _faces = faces,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _FaceDetectPainter(_faces, _originalImageSize);
  }
}
class _FaceDetectPainter extends BoxPainter {
  final List<VisionFace> _faces;
  final Size _originalImageSize;
  _FaceDetectPainter(faces, originalImageSize)
      : _faces = faces,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var face in _faces) {
      final _rect = Rect.fromLTRB(
          offset.dx + face.rect.left / _widthRatio,
          offset.dy + face.rect.top / _heightRatio,
          offset.dx + face.rect.right / _widthRatio,
          offset.dy + face.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();
  }
}
class LabelDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionLabel> _labels;
  LabelDetectDecoration(List<VisionLabel> labels, Size originalImageSize)
      : _labels = labels,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _LabelDetectPainter(_labels, _originalImageSize);
  }
}
class _LabelDetectPainter extends BoxPainter {
  final List<VisionLabel> _labels;
  final Size _originalImageSize;
  _LabelDetectPainter(labels, originalImageSize)
      : _labels = labels,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var label in _labels) {
      final _rect = Rect.fromLTRB(
          offset.dx + label.rect.left / _widthRatio,
          offset.dy + label.rect.top / _heightRatio,
          offset.dx + label.rect.right / _widthRatio,
          offset.dy + label.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();
  }

}
