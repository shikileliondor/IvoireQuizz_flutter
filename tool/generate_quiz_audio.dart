import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 44100;
const double bpm = 104;
const double beat = 60 / bpm;
const int bars = 12;
const double duration = bars * 4 * beat;

double _phase(double hz, double t) => 2 * math.pi * hz * t;
double _sine(double hz, double t) => math.sin(_phase(hz, t));
double _triangle(double hz, double t) =>
    2 / math.pi * math.asin(math.sin(_phase(hz, t)));

double _env(double t, double length,
    {double attack = .015, double release = .18}) {
  if (t < 0 || t >= length) return 0;
  return math.min(1, t / attack) * math.min(1, (length - t) / release);
}

double _marimba(double hz, double t, double length) {
  if (t < 0 || t >= length) return 0;
  final e = _env(t, length, attack: .006, release: .15) * math.exp(-4.2 * t);
  return e *
      (_sine(hz, t) + .32 * _sine(hz * 2.01, t) + .12 * _sine(hz * 3.97, t));
}

double _pad(double hz, double t, double length) {
  final e = _env(t, length, attack: .28, release: .4);
  return e * (_triangle(hz, t) * .55 + _sine(hz * 2, t) * .12);
}

double _bass(double hz, double t, double length) {
  if (t < 0 || t >= length) return 0;
  final e = _env(t, length, attack: .012, release: .12) * math.exp(-.65 * t);
  return e * (_sine(hz, t) + .18 * _sine(hz * 2, t));
}

double _noise(int index) {
  var x = (index * 1103515245 + 12345) & 0x7fffffff;
  x = (x * 1103515245 + 12345) & 0x7fffffff;
  return x / 0x3fffffff - 1;
}

double _kick(double t) {
  if (t < 0 || t > .22) return 0;
  final hz = 105 - 62 * (t / .22);
  return _sine(hz, t) * math.exp(-18 * t);
}

double _shaker(double t, int sample) {
  if (t < 0 || t > .07) return 0;
  return _noise(sample) * math.exp(-48 * t);
}

List<double> _music() {
  // Cmaj7 · Am7 · Fmaj7 · G6, trois cycles pour une boucle de 27,7 s.
  const chords = <List<double>>[
    [261.63, 329.63, 392.00, 493.88],
    [220.00, 261.63, 329.63, 392.00],
    [174.61, 220.00, 261.63, 329.63],
    [196.00, 246.94, 293.66, 329.63],
  ];
  const bass = <double>[65.41, 55.00, 43.65, 49.00];
  const motif = <int>[0, 1, 2, 1, 3, 2, 1, 2];
  final count = (duration * sampleRate).round();
  final samples = List<double>.filled(count, 0);

  for (var i = 0; i < count; i++) {
    final t = i / sampleRate;
    final bar = (t / (4 * beat)).floor();
    final chordIndex = bar % 4;
    final localBar = t % (4 * beat);
    final chord = chords[chordIndex];
    var value = 0.0;

    for (final hz in chord) {
      value += _pad(hz / 2, localBar, 4 * beat) * .027;
    }
    value += _bass(bass[chordIndex], localBar, 1.65 * beat) * .15;
    value +=
        _bass(bass[chordIndex] * 1.5, localBar - 2 * beat, 1.55 * beat) * .08;

    final eighth = (localBar / (beat / 2)).floor().clamp(0, 7);
    final noteStart = eighth * beat / 2;
    final noteHz = chord[motif[eighth] % chord.length] * (eighth.isOdd ? 2 : 1);
    value += _marimba(noteHz, localBar - noteStart, .42 * beat) * .20;

    for (var b = 0; b < 4; b++) {
      value += _kick(localBar - b * beat) * .075;
      value += _shaker(localBar - (b + .5) * beat, i) * .025;
    }

    // Un très léger mouvement stéréo simulé dans le timbre mono.
    value += _sine(880, t) * _sine(.18, t) * .0025;
    samples[i] = value;
  }

  // Raccord sans clic : croisement des 80 dernières millisecondes avec le début.
  final crossfade = (.08 * sampleRate).round();
  for (var i = 0; i < crossfade; i++) {
    final a = i / crossfade;
    final endIndex = count - crossfade + i;
    samples[endIndex] = samples[endIndex] * (1 - a) + samples[i] * a;
  }
  return samples;
}

List<double> _jingle(List<double> notes,
    {double spacing = .13, bool soft = false}) {
  final length = notes.length * spacing + .35;
  return List<double>.generate((length * sampleRate).round(), (i) {
    final t = i / sampleRate;
    var value = 0.0;
    for (var n = 0; n < notes.length; n++) {
      final local = t - n * spacing;
      value += _marimba(notes[n], local, spacing + .24) * (soft ? .26 : .38);
      value += _pad(notes[n] / 2, local, spacing + .28) * .055;
    }
    return value;
  });
}

void _writeWav(String path, List<double> input) {
  final peak = input.fold<double>(0, (p, v) => math.max(p, v.abs()));
  final gain = peak > .86 ? .86 / peak : 1.0;
  final data = ByteData(44 + input.length * 2);
  void tag(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, 36 + input.length * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, input.length * 2, Endian.little);
  for (var i = 0; i < input.length; i++) {
    data.setInt16(44 + i * 2,
        (input[i] * gain * 32767).round().clamp(-32767, 32767), Endian.little);
  }
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data.buffer.asUint8List());
}

void main() {
  _writeWav('assets/audio/background.wav', _music());
  _writeWav('assets/audio/correct.wav', _jingle([659.25, 783.99, 1046.50]));
  _writeWav('assets/audio/incorrect.wav',
      _jingle([392.00, 329.63], spacing: .18, soft: true));
  _writeWav('assets/audio/victory.wav',
      _jingle([523.25, 659.25, 783.99, 1046.50], spacing: .15));
  _writeWav('assets/audio/defeat.wav',
      _jingle([440.00, 392.00, 329.63], spacing: .19, soft: true));
}
