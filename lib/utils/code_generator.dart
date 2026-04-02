import 'dart:math';

String generateRandomCode(int length) {
  final String charList = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final Random rand = Random.secure();

  final StringBuffer code = StringBuffer();

  for (var i = 0; i < length; i++) {
    final int index = rand.nextInt(charList.length);
    code.write(charList[index]);
  }

  return code.toString();
}