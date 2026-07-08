import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// --- Database Tables DSL Definitions ---

class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artistId => text()();
  TextColumn get albumId => text()();
  IntColumn get duration => integer()();
  TextColumn get artwork => text()();
  TextColumn get thumbnail => text()();
  BoolColumn get liked => boolean().withDefault(const Constant(false))();
  BoolColumn get downloaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastPlayed => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  TextColumn get provider => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Artists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get image => text()();
  TextColumn get description => text()();
  IntColumn get subscriberCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Albums extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artistId => text()();
  TextColumn get cover => text()();
  IntColumn get year => integer()();
  IntColumn get duration => integer()();
  IntColumn get trackCount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get cover => text()();
  TextColumn get owner => text()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PlaylistSongs extends Table {
  TextColumn get playlistId => text()();
  TextColumn get songId => text()();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

class History extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get songId => text()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get position => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get device => text()();
}

class Favorites extends Table {
  TextColumn get songId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId};
}

class Downloads extends Table {
  TextColumn get songId => text()();
  TextColumn get status => text()(); // queued, downloading, paused, completed, failed, cancelled
  IntColumn get progress => integer().withDefault(const Constant(0))();
  TextColumn get localPath => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId};
}

class LyricsTable extends Table {
  TextColumn get songId => text()();
  TextColumn get plainLyrics => text()();
  TextColumn get syncedLyrics => text().nullable()(); // JSON map string
  TextColumn get provider => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId};
}

class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

class SearchHistory extends Table {
  TextColumn get query => text()();
  DateTimeColumn get searchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {query};
}

class CachedHomeFeed extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get feedJson => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

class CachedRecommendations extends Table {
  TextColumn get songId => text()();
  TextColumn get recommendationsJson => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId};
}

// --- Drift Accessor (DAO) Definitions ---

@DriftAccessor(tables: [Songs])
class SongDao extends DatabaseAccessor<AppDatabase> with _$SongDaoMixin {
  SongDao(super.db);

  Future<List<Song>> getAllSongs() => select(songs).get();
  Future<Song?> getSongById(String id) => (select(songs)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertSong(SongsCompanion entry) => into(songs).insertOnConflictUpdate(entry);
  Future<bool> deleteSong(String id) => (delete(songs)..where((t) => t.id.equals(id))).go().then((r) => r > 0);
}

@DriftAccessor(tables: [Albums])
class AlbumDao extends DatabaseAccessor<AppDatabase> with _$AlbumDaoMixin {
  AlbumDao(super.db);

  Future<List<Album>> getAllAlbums() => select(albums).get();
  Future<Album?> getAlbumById(String id) => (select(albums)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertAlbum(AlbumsCompanion entry) => into(albums).insertOnConflictUpdate(entry);
}

@DriftAccessor(tables: [Artists])
class ArtistDao extends DatabaseAccessor<AppDatabase> with _$ArtistDaoMixin {
  ArtistDao(super.db);

  Future<List<Artist>> getAllArtists() => select(artists).get();
  Future<Artist?> getArtistById(String id) => (select(artists)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertArtist(ArtistsCompanion entry) => into(artists).insertOnConflictUpdate(entry);
}

@DriftAccessor(tables: [Playlists, PlaylistSongs])
class PlaylistDao extends DatabaseAccessor<AppDatabase> with _$PlaylistDaoMixin {
  PlaylistDao(super.db);

  Future<List<Playlist>> getAllPlaylists() => select(playlists).get();
  Future<Playlist?> getPlaylistById(String id) => (select(playlists)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertPlaylist(PlaylistsCompanion entry) => into(playlists).insertOnConflictUpdate(entry);
  Future<void> addSongToPlaylist(PlaylistSongsCompanion entry) => into(playlistSongs).insertOnConflictUpdate(entry);
}

@DriftAccessor(tables: [History])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.db);

  Future<List<HistoryData>> getRecentlyPlayed() => (select(history)..orderBy([(t) => OrderingTerm.desc(t.playedAt)])).get();
  Future<int> addToHistory(HistoryCompanion entry) => into(history).insert(entry);
}

@DriftAccessor(tables: [LyricsTable])
class LyricsDao extends DatabaseAccessor<AppDatabase> with _$LyricsDaoMixin {
  LyricsDao(super.db);

  Future<LyricsTableData?> getLyrics(String songId) => (select(lyricsTable)..where((t) => t.songId.equals(songId))).getSingleOrNull();
  Future<int> insertLyrics(LyricsTableCompanion entry) => into(lyricsTable).insertOnConflictUpdate(entry);
}

@DriftAccessor(tables: [SettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<SettingsTableData?> getSetting(String key) => (select(settingsTable)..where((t) => t.key.equals(key))).getSingleOrNull();
  Future<int> insertSetting(SettingsTableCompanion entry) => into(settingsTable).insertOnConflictUpdate(entry);
}

@DriftAccessor(tables: [Favorites])
class FavoritesDao extends DatabaseAccessor<AppDatabase> with _$FavoritesDaoMixin {
  FavoritesDao(super.db);

  Future<List<Favorite>> getAllFavorites() => select(favorites).get();
  Future<int> addFavorite(FavoritesCompanion entry) => into(favorites).insertOnConflictUpdate(entry);
  Future<bool> removeFavorite(String songId) => (delete(favorites)..where((t) => t.songId.equals(songId))).go().then((r) => r > 0);
}

@DriftAccessor(tables: [SearchHistory])
class SearchDao extends DatabaseAccessor<AppDatabase> with _$SearchDaoMixin {
  SearchDao(super.db);

  Future<List<SearchHistoryData>> getSearchHistory() => (select(searchHistory)..orderBy([(t) => OrderingTerm.desc(t.searchedAt)])).get();
  Future<int> addSearch(SearchHistoryCompanion entry) => into(searchHistory).insertOnConflictUpdate(entry);
}

// --- Main App Database ---

@DriftDatabase(
  tables: [
    Songs,
    Artists,
    Albums,
    Playlists,
    PlaylistSongs,
    History,
    Favorites,
    Downloads,
    LyricsTable,
    SettingsTable,
    SearchHistory,
    CachedHomeFeed,
    CachedRecommendations,
  ],
  daos: [
    SongDao,
    AlbumDao,
    ArtistDao,
    PlaylistDao,
    HistoryDao,
    LyricsDao,
    SettingsDao,
    FavoritesDao,
    SearchDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Schema migrations upgrades
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'da_music.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
