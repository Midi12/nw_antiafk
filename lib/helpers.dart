import 'dart:math';

final kRandom = Random();

int getRandomInt(int min, int max, {Random? randomDevice}) {
  randomDevice ??= kRandom;

  return min + randomDevice.nextInt(max - min + 1);
}

String getRandomString(int length, {Random? randomDevice}) {
  return String.fromCharCodes(Iterable.generate(
      length, (_) => getRandomInt(32, 126, randomDevice: randomDevice)));
}
