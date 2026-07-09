class MusicDNA {
  final List<String> topArtists;
  final List<String> topAlbums;
  final List<String> topSongs;
  final List<String> favoriteGenres;
  final List<String> favoriteLanguages;
  final List<String> favoriteDecades;
  final String listeningMood;
  final String peakListeningTime;
  final double averageSessionLengthMinutes;
  final double replayRate;
  final double skipRate;
  final double completionRate;
  final int downloadCount;
  final int favoriteCount;

  // Numerical affinity scores for granular updates and logs
  final Map<String, double> artistAffinities;
  final Map<String, double> genreAffinities;
  final Map<String, double> songAffinities;
  final Map<String, double> albumAffinities;

  const MusicDNA({
    this.topArtists = const [],
    this.topAlbums = const [],
    this.topSongs = const [],
    this.favoriteGenres = const [],
    this.favoriteLanguages = const [],
    this.favoriteDecades = const [],
    this.listeningMood = 'Neutral',
    this.peakListeningTime = 'N/A',
    this.averageSessionLengthMinutes = 0.0,
    this.replayRate = 0.0,
    this.skipRate = 0.0,
    this.completionRate = 0.0,
    this.downloadCount = 0,
    this.favoriteCount = 0,
    this.artistAffinities = const {},
    this.genreAffinities = const {},
    this.songAffinities = const {},
    this.albumAffinities = const {},
  });

  factory MusicDNA.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseAffinities(Map<String, dynamic>? data) {
      if (data == null) return const {};
      return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    return MusicDNA(
      topArtists: List<String>.from(json['topArtists'] ?? const []),
      topAlbums: List<String>.from(json['topAlbums'] ?? const []),
      topSongs: List<String>.from(json['topSongs'] ?? const []),
      favoriteGenres: List<String>.from(json['favoriteGenres'] ?? const []),
      favoriteLanguages: List<String>.from(json['favoriteLanguages'] ?? const []),
      favoriteDecades: List<String>.from(json['favoriteDecades'] ?? const []),
      listeningMood: json['listeningMood'] ?? 'Neutral',
      peakListeningTime: json['peakListeningTime'] ?? 'N/A',
      averageSessionLengthMinutes: (json['averageSessionLengthMinutes'] ?? 0.0).toDouble(),
      replayRate: (json['replayRate'] ?? 0.0).toDouble(),
      skipRate: (json['skipRate'] ?? 0.0).toDouble(),
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      downloadCount: json['downloadCount'] ?? 0,
      favoriteCount: json['favoriteCount'] ?? 0,
      artistAffinities: parseAffinities(json['artistAffinities']),
      genreAffinities: parseAffinities(json['genreAffinities']),
      songAffinities: parseAffinities(json['songAffinities']),
      albumAffinities: parseAffinities(json['albumAffinities']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topArtists': topArtists,
      'topAlbums': topAlbums,
      'topSongs': topSongs,
      'favoriteGenres': favoriteGenres,
      'favoriteLanguages': favoriteLanguages,
      'favoriteDecades': favoriteDecades,
      'listeningMood': listeningMood,
      'peakListeningTime': peakListeningTime,
      'averageSessionLengthMinutes': averageSessionLengthMinutes,
      'replayRate': replayRate,
      'skipRate': skipRate,
      'completionRate': completionRate,
      'downloadCount': downloadCount,
      'favoriteCount': favoriteCount,
      'artistAffinities': artistAffinities,
      'genreAffinities': genreAffinities,
      'songAffinities': songAffinities,
      'albumAffinities': albumAffinities,
    };
  }
}
