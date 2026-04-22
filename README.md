# recycle_go

Mobile application assignment RSW Y2S3 G10

Before the testing model classify the recycle item at the user part
ensure you copy these code and find the function name and paste them because these can help the model more accurate

**Function Name processImage:**
dynamic _processImage(img.Image imgData) {
  var buffer = Float32List(1 * 300 * 300 * 3);
  int idx = 0;
  for (var y = 0; y < 300; y++) {
    for (var x = 0; x < 300; x++) {
      var p = imgData.getPixel(x, y);
      buffer[idx++] = p.r / 255.0;
      buffer[idx++] = p.g / 255.0;
      buffer[idx++] = p.b / 255.0;
    }
  }
  return buffer.reshape([1, 300, 300, 3]);
}

**Function Name _parseResults:**
void _parseResults(List<double> scores) {
  List<Map<String, dynamic>> temp = [];
  double highestScore = 0.0;
  int highestIndex = -1;
  for (int i = 0; i < scores.length; i++) {
    if (scores[i] > highestScore) {
      highestScore = scores[i];
      highestIndex = i;
    }
  }
  if (highestScore > 0.75 && highestIndex < labels.length) {
    temp.add({
      "tag": labels[highestIndex],
      "w": 200.0,
      "h": 200.0,
      "box": [0.0, 0.0, 300.0, 300.0]
    });
  }
  detections = temp;
}
