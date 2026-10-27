class MeditationTrack {
  final String id, category, title, imageAsset, audioAsset;
  const MeditationTrack(
      this.id, this.category, this.title, this.imageAsset, this.audioAsset);
}

const meditationCategories = <String>[
  'Sleep',
  'Ambient',
  'Nature',
  'Instrumental'
];

const meditationTracks = <MeditationTrack>[
  MeditationTrack('sleep_01', 'sleep', 'Evening Calm',
      'assets/meditation/sleep/01.jpeg', 'assets/meditation/sleep/01.mp3'),
  MeditationTrack('sleep_02', 'sleep', 'Deep Rest',
      'assets/meditation/sleep/02.jpg', 'assets/meditation/sleep/02.mp3'),
  MeditationTrack('sleep_03', 'sleep', 'Soft Frequencies',
      'assets/meditation/sleep/03.jpg', 'assets/meditation/sleep/03.mp3'),
  MeditationTrack('sleep_04', 'sleep', 'Quiet Beauty',
      'assets/meditation/sleep/04.jpg', 'assets/meditation/sleep/04.mp3'),
  MeditationTrack('sleep_05', 'sleep', 'Sleep Drift',
      'assets/meditation/sleep/05.jpg', 'assets/meditation/sleep/05.mp3'),
  MeditationTrack('sleep_06', 'sleep', 'Night Meditation',
      'assets/meditation/sleep/06.png', 'assets/meditation/sleep/06.mp3'),
  MeditationTrack('ambient_01', 'ambient', 'Soft Meditation',
      'assets/meditation/ambient/01.jpg', 'assets/meditation/ambient/01.mp3'),
  MeditationTrack('ambient_02', 'ambient', 'Flute Flow',
      'assets/meditation/ambient/02.jpg', 'assets/meditation/ambient/02.mp3'),
  MeditationTrack('ambient_03', 'ambient', 'Relaxing Atmosphere',
      'assets/meditation/ambient/03.jpg', 'assets/meditation/ambient/03.mp3'),
  MeditationTrack('ambient_04', 'ambient', 'Ambient Pause',
      'assets/meditation/ambient/04.jpg', 'assets/meditation/ambient/04.mp3'),
  MeditationTrack('ambient_05', 'ambient', 'Mountain Air',
      'assets/meditation/ambient/05.jpg', 'assets/meditation/ambient/05.mp3'),
  MeditationTrack('ambient_06', 'ambient', 'Stillness',
      'assets/meditation/ambient/06.jpeg', 'assets/meditation/ambient/06.mp3'),
  MeditationTrack('nature_01', 'nature', 'Open Skies',
      'assets/meditation/nature/01.jpg', 'assets/meditation/nature/01.mp3'),
  MeditationTrack('nature_02', 'nature', 'Nature Calm',
      'assets/meditation/nature/02.jpg', 'assets/meditation/nature/02.mp3'),
  MeditationTrack('nature_03', 'nature', 'Gentle Outdoors',
      'assets/meditation/nature/03.jpg', 'assets/meditation/nature/03.mp3'),
  MeditationTrack('nature_04', 'nature', 'Nature Meditation',
      'assets/meditation/nature/04.jpg', 'assets/meditation/nature/04.mp3'),
  MeditationTrack('nature_05', 'nature', 'Quiet Nature',
      'assets/meditation/nature/05.jpg', 'assets/meditation/nature/05.mp3'),
  MeditationTrack('nature_06', 'nature', 'Gentle Nature',
      'assets/meditation/nature/06.jpg', 'assets/meditation/nature/06.mp3'),
  MeditationTrack(
      'instrumental_01',
      'instrumental',
      'Soft Focus',
      'assets/meditation/instrumental/01.jpg',
      'assets/meditation/instrumental/01.mp3'),
  MeditationTrack(
      'instrumental_02',
      'instrumental',
      'Instrumental Flow',
      'assets/meditation/instrumental/02.jpg',
      'assets/meditation/instrumental/02.mp3'),
  MeditationTrack(
      'instrumental_03',
      'instrumental',
      'Meditation Melody',
      'assets/meditation/instrumental/03.jpg',
      'assets/meditation/instrumental/03.mp3'),
  MeditationTrack(
      'instrumental_04',
      'instrumental',
      'Mindful Notes',
      'assets/meditation/instrumental/04.jpg',
      'assets/meditation/instrumental/04.mp3'),
  MeditationTrack(
      'instrumental_05',
      'instrumental',
      'Gentle Instrumental',
      'assets/meditation/instrumental/05.jpg',
      'assets/meditation/instrumental/05.mp3'),
  MeditationTrack(
      'instrumental_06',
      'instrumental',
      'Piano Pause',
      'assets/meditation/instrumental/06.jpg',
      'assets/meditation/instrumental/06.mp3'),
];
