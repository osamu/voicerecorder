// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RecordingsTable extends Recordings
    with TableInfo<$RecordingsTable, Recording> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _driveFileIdMeta = const VerificationMeta(
    'driveFileId',
  );
  @override
  late final GeneratedColumn<String> driveFileId = GeneratedColumn<String>(
    'drive_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _txtDriveFileIdMeta = const VerificationMeta(
    'txtDriveFileId',
  );
  @override
  late final GeneratedColumn<String> txtDriveFileId = GeneratedColumn<String>(
    'txt_drive_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<UploadState, String> uploadState =
      GeneratedColumn<String>(
        'upload_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<UploadState>($RecordingsTable.$converteruploadState);
  @override
  late final GeneratedColumnWithTypeConverter<TranscriptState, String>
  transcriptState = GeneratedColumn<String>(
    'transcript_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('off'),
  ).withConverter<TranscriptState>($RecordingsTable.$convertertranscriptState);
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Codec, String> codec =
      GeneratedColumn<String>(
        'codec',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Codec>($RecordingsTable.$convertercodec);
  static const VerificationMeta _transcriptLocalPathMeta =
      const VerificationMeta('transcriptLocalPath');
  @override
  late final GeneratedColumn<String> transcriptLocalPath =
      GeneratedColumn<String>(
        'transcript_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    durationMs,
    localPath,
    title,
    driveFileId,
    txtDriveFileId,
    uploadState,
    transcriptState,
    sizeBytes,
    codec,
    transcriptLocalPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recording> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('drive_file_id')) {
      context.handle(
        _driveFileIdMeta,
        driveFileId.isAcceptableOrUnknown(
          data['drive_file_id']!,
          _driveFileIdMeta,
        ),
      );
    }
    if (data.containsKey('txt_drive_file_id')) {
      context.handle(
        _txtDriveFileIdMeta,
        txtDriveFileId.isAcceptableOrUnknown(
          data['txt_drive_file_id']!,
          _txtDriveFileIdMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('transcript_local_path')) {
      context.handle(
        _transcriptLocalPathMeta,
        transcriptLocalPath.isAcceptableOrUnknown(
          data['transcript_local_path']!,
          _transcriptLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recording map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recording(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      driveFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_file_id'],
      ),
      txtDriveFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}txt_drive_file_id'],
      ),
      uploadState: $RecordingsTable.$converteruploadState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}upload_state'],
        )!,
      ),
      transcriptState: $RecordingsTable.$convertertranscriptState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}transcript_state'],
        )!,
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      codec: $RecordingsTable.$convertercodec.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}codec'],
        )!,
      ),
      transcriptLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript_local_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecordingsTable createAlias(String alias) {
    return $RecordingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UploadState, String, String> $converteruploadState =
      const EnumNameConverter<UploadState>(UploadState.values);
  static JsonTypeConverter2<TranscriptState, String, String>
  $convertertranscriptState = const EnumNameConverter<TranscriptState>(
    TranscriptState.values,
  );
  static JsonTypeConverter2<Codec, String, String> $convertercodec =
      const EnumNameConverter<Codec>(Codec.values);
}

class Recording extends DataClass implements Insertable<Recording> {
  /// UUID v4。ローカル録音開始時に生成。Drive appProperties(vrId) にも同値を付与。
  final String id;

  /// 録音開始時刻。ISO8601 + タイムゾーンオフセット（端末ローカル時刻基準）。
  final String startedAt;

  /// 録音時間（ミリ秒）。リカバリ復元時は推定値。
  final int durationMs;

  /// 端末内ファイルの絶対パス。逼迫時自動削除後は NULL。
  final String? localPath;

  /// ユーザー指定タイトル（ファイル名のタイトル部）。空なら日時のみの名前。
  final String title;

  /// 音声ファイルの Drive fileId。アップ成功時に保存。
  final String? driveFileId;

  /// .txt の Drive fileId。
  final String? txtDriveFileId;

  /// アップロード状態バッジ（射影値）。
  final UploadState uploadState;

  /// 文字起こし状態バッジ（射影値）。
  final TranscriptState transcriptState;

  /// ファイルサイズ（バイト）。
  final int sizeBytes;

  /// 音声コーデック（拡張子・MIME 決定に使用）。
  final Codec codec;

  /// 生成済み .txt のローカルパス（閲覧用）。
  final String? transcriptLocalPath;

  /// 監査・ソート用（ISO8601）。
  final String createdAt;
  final String updatedAt;
  const Recording({
    required this.id,
    required this.startedAt,
    required this.durationMs,
    this.localPath,
    required this.title,
    this.driveFileId,
    this.txtDriveFileId,
    required this.uploadState,
    required this.transcriptState,
    required this.sizeBytes,
    required this.codec,
    this.transcriptLocalPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<String>(startedAt);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || driveFileId != null) {
      map['drive_file_id'] = Variable<String>(driveFileId);
    }
    if (!nullToAbsent || txtDriveFileId != null) {
      map['txt_drive_file_id'] = Variable<String>(txtDriveFileId);
    }
    {
      map['upload_state'] = Variable<String>(
        $RecordingsTable.$converteruploadState.toSql(uploadState),
      );
    }
    {
      map['transcript_state'] = Variable<String>(
        $RecordingsTable.$convertertranscriptState.toSql(transcriptState),
      );
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    {
      map['codec'] = Variable<String>(
        $RecordingsTable.$convertercodec.toSql(codec),
      );
    }
    if (!nullToAbsent || transcriptLocalPath != null) {
      map['transcript_local_path'] = Variable<String>(transcriptLocalPath);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  RecordingsCompanion toCompanion(bool nullToAbsent) {
    return RecordingsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      durationMs: Value(durationMs),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      title: Value(title),
      driveFileId: driveFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(driveFileId),
      txtDriveFileId: txtDriveFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(txtDriveFileId),
      uploadState: Value(uploadState),
      transcriptState: Value(transcriptState),
      sizeBytes: Value(sizeBytes),
      codec: Value(codec),
      transcriptLocalPath: transcriptLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(transcriptLocalPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Recording.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recording(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      title: serializer.fromJson<String>(json['title']),
      driveFileId: serializer.fromJson<String?>(json['driveFileId']),
      txtDriveFileId: serializer.fromJson<String?>(json['txtDriveFileId']),
      uploadState: $RecordingsTable.$converteruploadState.fromJson(
        serializer.fromJson<String>(json['uploadState']),
      ),
      transcriptState: $RecordingsTable.$convertertranscriptState.fromJson(
        serializer.fromJson<String>(json['transcriptState']),
      ),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      codec: $RecordingsTable.$convertercodec.fromJson(
        serializer.fromJson<String>(json['codec']),
      ),
      transcriptLocalPath: serializer.fromJson<String?>(
        json['transcriptLocalPath'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<String>(startedAt),
      'durationMs': serializer.toJson<int>(durationMs),
      'localPath': serializer.toJson<String?>(localPath),
      'title': serializer.toJson<String>(title),
      'driveFileId': serializer.toJson<String?>(driveFileId),
      'txtDriveFileId': serializer.toJson<String?>(txtDriveFileId),
      'uploadState': serializer.toJson<String>(
        $RecordingsTable.$converteruploadState.toJson(uploadState),
      ),
      'transcriptState': serializer.toJson<String>(
        $RecordingsTable.$convertertranscriptState.toJson(transcriptState),
      ),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'codec': serializer.toJson<String>(
        $RecordingsTable.$convertercodec.toJson(codec),
      ),
      'transcriptLocalPath': serializer.toJson<String?>(transcriptLocalPath),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Recording copyWith({
    String? id,
    String? startedAt,
    int? durationMs,
    Value<String?> localPath = const Value.absent(),
    String? title,
    Value<String?> driveFileId = const Value.absent(),
    Value<String?> txtDriveFileId = const Value.absent(),
    UploadState? uploadState,
    TranscriptState? transcriptState,
    int? sizeBytes,
    Codec? codec,
    Value<String?> transcriptLocalPath = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => Recording(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    durationMs: durationMs ?? this.durationMs,
    localPath: localPath.present ? localPath.value : this.localPath,
    title: title ?? this.title,
    driveFileId: driveFileId.present ? driveFileId.value : this.driveFileId,
    txtDriveFileId: txtDriveFileId.present
        ? txtDriveFileId.value
        : this.txtDriveFileId,
    uploadState: uploadState ?? this.uploadState,
    transcriptState: transcriptState ?? this.transcriptState,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    codec: codec ?? this.codec,
    transcriptLocalPath: transcriptLocalPath.present
        ? transcriptLocalPath.value
        : this.transcriptLocalPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Recording copyWithCompanion(RecordingsCompanion data) {
    return Recording(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      title: data.title.present ? data.title.value : this.title,
      driveFileId: data.driveFileId.present
          ? data.driveFileId.value
          : this.driveFileId,
      txtDriveFileId: data.txtDriveFileId.present
          ? data.txtDriveFileId.value
          : this.txtDriveFileId,
      uploadState: data.uploadState.present
          ? data.uploadState.value
          : this.uploadState,
      transcriptState: data.transcriptState.present
          ? data.transcriptState.value
          : this.transcriptState,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      codec: data.codec.present ? data.codec.value : this.codec,
      transcriptLocalPath: data.transcriptLocalPath.present
          ? data.transcriptLocalPath.value
          : this.transcriptLocalPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recording(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('localPath: $localPath, ')
          ..write('title: $title, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('txtDriveFileId: $txtDriveFileId, ')
          ..write('uploadState: $uploadState, ')
          ..write('transcriptState: $transcriptState, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('codec: $codec, ')
          ..write('transcriptLocalPath: $transcriptLocalPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    durationMs,
    localPath,
    title,
    driveFileId,
    txtDriveFileId,
    uploadState,
    transcriptState,
    sizeBytes,
    codec,
    transcriptLocalPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recording &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.durationMs == this.durationMs &&
          other.localPath == this.localPath &&
          other.title == this.title &&
          other.driveFileId == this.driveFileId &&
          other.txtDriveFileId == this.txtDriveFileId &&
          other.uploadState == this.uploadState &&
          other.transcriptState == this.transcriptState &&
          other.sizeBytes == this.sizeBytes &&
          other.codec == this.codec &&
          other.transcriptLocalPath == this.transcriptLocalPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecordingsCompanion extends UpdateCompanion<Recording> {
  final Value<String> id;
  final Value<String> startedAt;
  final Value<int> durationMs;
  final Value<String?> localPath;
  final Value<String> title;
  final Value<String?> driveFileId;
  final Value<String?> txtDriveFileId;
  final Value<UploadState> uploadState;
  final Value<TranscriptState> transcriptState;
  final Value<int> sizeBytes;
  final Value<Codec> codec;
  final Value<String?> transcriptLocalPath;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const RecordingsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.localPath = const Value.absent(),
    this.title = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.txtDriveFileId = const Value.absent(),
    this.uploadState = const Value.absent(),
    this.transcriptState = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.codec = const Value.absent(),
    this.transcriptLocalPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordingsCompanion.insert({
    required String id,
    required String startedAt,
    this.durationMs = const Value.absent(),
    this.localPath = const Value.absent(),
    this.title = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.txtDriveFileId = const Value.absent(),
    this.uploadState = const Value.absent(),
    this.transcriptState = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required Codec codec,
    this.transcriptLocalPath = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       codec = Value(codec),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Recording> custom({
    Expression<String>? id,
    Expression<String>? startedAt,
    Expression<int>? durationMs,
    Expression<String>? localPath,
    Expression<String>? title,
    Expression<String>? driveFileId,
    Expression<String>? txtDriveFileId,
    Expression<String>? uploadState,
    Expression<String>? transcriptState,
    Expression<int>? sizeBytes,
    Expression<String>? codec,
    Expression<String>? transcriptLocalPath,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (localPath != null) 'local_path': localPath,
      if (title != null) 'title': title,
      if (driveFileId != null) 'drive_file_id': driveFileId,
      if (txtDriveFileId != null) 'txt_drive_file_id': txtDriveFileId,
      if (uploadState != null) 'upload_state': uploadState,
      if (transcriptState != null) 'transcript_state': transcriptState,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (codec != null) 'codec': codec,
      if (transcriptLocalPath != null)
        'transcript_local_path': transcriptLocalPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordingsCompanion copyWith({
    Value<String>? id,
    Value<String>? startedAt,
    Value<int>? durationMs,
    Value<String?>? localPath,
    Value<String>? title,
    Value<String?>? driveFileId,
    Value<String?>? txtDriveFileId,
    Value<UploadState>? uploadState,
    Value<TranscriptState>? transcriptState,
    Value<int>? sizeBytes,
    Value<Codec>? codec,
    Value<String?>? transcriptLocalPath,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecordingsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      durationMs: durationMs ?? this.durationMs,
      localPath: localPath ?? this.localPath,
      title: title ?? this.title,
      driveFileId: driveFileId ?? this.driveFileId,
      txtDriveFileId: txtDriveFileId ?? this.txtDriveFileId,
      uploadState: uploadState ?? this.uploadState,
      transcriptState: transcriptState ?? this.transcriptState,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      codec: codec ?? this.codec,
      transcriptLocalPath: transcriptLocalPath ?? this.transcriptLocalPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (driveFileId.present) {
      map['drive_file_id'] = Variable<String>(driveFileId.value);
    }
    if (txtDriveFileId.present) {
      map['txt_drive_file_id'] = Variable<String>(txtDriveFileId.value);
    }
    if (uploadState.present) {
      map['upload_state'] = Variable<String>(
        $RecordingsTable.$converteruploadState.toSql(uploadState.value),
      );
    }
    if (transcriptState.present) {
      map['transcript_state'] = Variable<String>(
        $RecordingsTable.$convertertranscriptState.toSql(transcriptState.value),
      );
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (codec.present) {
      map['codec'] = Variable<String>(
        $RecordingsTable.$convertercodec.toSql(codec.value),
      );
    }
    if (transcriptLocalPath.present) {
      map['transcript_local_path'] = Variable<String>(
        transcriptLocalPath.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('localPath: $localPath, ')
          ..write('title: $title, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('txtDriveFileId: $txtDriveFileId, ')
          ..write('uploadState: $uploadState, ')
          ..write('transcriptState: $transcriptState, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('codec: $codec, ')
          ..write('transcriptLocalPath: $transcriptLocalPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UploadJobsTable extends UploadJobs
    with TableInfo<$UploadJobsTable, UploadJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<String> recordingId = GeneratedColumn<String>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recordings (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<UploadJobKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<UploadJobKind>($UploadJobsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<UploadJobState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<UploadJobState>($UploadJobsTable.$converterstate);
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<String> nextRetryAt = GeneratedColumn<String>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resumableUriMeta = const VerificationMeta(
    'resumableUri',
  );
  @override
  late final GeneratedColumn<String> resumableUri = GeneratedColumn<String>(
    'resumable_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _driveFolderIdMeta = const VerificationMeta(
    'driveFolderId',
  );
  @override
  late final GeneratedColumn<String> driveFolderId = GeneratedColumn<String>(
    'drive_folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordingId,
    kind,
    state,
    retryCount,
    nextRetryAt,
    resumableUri,
    driveFolderId,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<UploadJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('resumable_uri')) {
      context.handle(
        _resumableUriMeta,
        resumableUri.isAcceptableOrUnknown(
          data['resumable_uri']!,
          _resumableUriMeta,
        ),
      );
    }
    if (data.containsKey('drive_folder_id')) {
      context.handle(
        _driveFolderIdMeta,
        driveFolderId.isAcceptableOrUnknown(
          data['drive_folder_id']!,
          _driveFolderIdMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {recordingId, kind},
  ];
  @override
  UploadJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_id'],
      )!,
      kind: $UploadJobsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      state: $UploadJobsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_retry_at'],
      ),
      resumableUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resumable_uri'],
      ),
      driveFolderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_folder_id'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UploadJobsTable createAlias(String alias) {
    return $UploadJobsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UploadJobKind, String, String> $converterkind =
      const EnumNameConverter<UploadJobKind>(UploadJobKind.values);
  static JsonTypeConverter2<UploadJobState, String, String> $converterstate =
      const EnumNameConverter<UploadJobState>(UploadJobState.values);
}

class UploadJob extends DataClass implements Insertable<UploadJob> {
  /// UUID。
  final String id;

  /// 対象録音（FK → recordings.id）。
  final String recordingId;

  /// audio / transcript。transcript は低優先度。
  final UploadJobKind kind;

  /// キュー状態機械。
  final UploadJobState state;

  /// リトライ回数。
  final int retryCount;

  /// 指数バックオフの次回試行時刻（ISO8601）。
  final String? nextRetryAt;

  /// Drive resumable session URI（再開用）。
  final String? resumableUri;

  /// アップ先（年-月フォルダ）の fileId。解決済みならキャッシュ。
  final String? driveFolderId;

  /// 直近エラー（機微情報を含めない）。
  final String? lastError;
  final String createdAt;
  final String updatedAt;
  const UploadJob({
    required this.id,
    required this.recordingId,
    required this.kind,
    required this.state,
    required this.retryCount,
    this.nextRetryAt,
    this.resumableUri,
    this.driveFolderId,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recording_id'] = Variable<String>(recordingId);
    {
      map['kind'] = Variable<String>(
        $UploadJobsTable.$converterkind.toSql(kind),
      );
    }
    {
      map['state'] = Variable<String>(
        $UploadJobsTable.$converterstate.toSql(state),
      );
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<String>(nextRetryAt);
    }
    if (!nullToAbsent || resumableUri != null) {
      map['resumable_uri'] = Variable<String>(resumableUri);
    }
    if (!nullToAbsent || driveFolderId != null) {
      map['drive_folder_id'] = Variable<String>(driveFolderId);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  UploadJobsCompanion toCompanion(bool nullToAbsent) {
    return UploadJobsCompanion(
      id: Value(id),
      recordingId: Value(recordingId),
      kind: Value(kind),
      state: Value(state),
      retryCount: Value(retryCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      resumableUri: resumableUri == null && nullToAbsent
          ? const Value.absent()
          : Value(resumableUri),
      driveFolderId: driveFolderId == null && nullToAbsent
          ? const Value.absent()
          : Value(driveFolderId),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UploadJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadJob(
      id: serializer.fromJson<String>(json['id']),
      recordingId: serializer.fromJson<String>(json['recordingId']),
      kind: $UploadJobsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      state: $UploadJobsTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<String?>(json['nextRetryAt']),
      resumableUri: serializer.fromJson<String?>(json['resumableUri']),
      driveFolderId: serializer.fromJson<String?>(json['driveFolderId']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordingId': serializer.toJson<String>(recordingId),
      'kind': serializer.toJson<String>(
        $UploadJobsTable.$converterkind.toJson(kind),
      ),
      'state': serializer.toJson<String>(
        $UploadJobsTable.$converterstate.toJson(state),
      ),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<String?>(nextRetryAt),
      'resumableUri': serializer.toJson<String?>(resumableUri),
      'driveFolderId': serializer.toJson<String?>(driveFolderId),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  UploadJob copyWith({
    String? id,
    String? recordingId,
    UploadJobKind? kind,
    UploadJobState? state,
    int? retryCount,
    Value<String?> nextRetryAt = const Value.absent(),
    Value<String?> resumableUri = const Value.absent(),
    Value<String?> driveFolderId = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => UploadJob(
    id: id ?? this.id,
    recordingId: recordingId ?? this.recordingId,
    kind: kind ?? this.kind,
    state: state ?? this.state,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    resumableUri: resumableUri.present ? resumableUri.value : this.resumableUri,
    driveFolderId: driveFolderId.present
        ? driveFolderId.value
        : this.driveFolderId,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UploadJob copyWithCompanion(UploadJobsCompanion data) {
    return UploadJob(
      id: data.id.present ? data.id.value : this.id,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      kind: data.kind.present ? data.kind.value : this.kind,
      state: data.state.present ? data.state.value : this.state,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      resumableUri: data.resumableUri.present
          ? data.resumableUri.value
          : this.resumableUri,
      driveFolderId: data.driveFolderId.present
          ? data.driveFolderId.value
          : this.driveFolderId,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadJob(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('kind: $kind, ')
          ..write('state: $state, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('resumableUri: $resumableUri, ')
          ..write('driveFolderId: $driveFolderId, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordingId,
    kind,
    state,
    retryCount,
    nextRetryAt,
    resumableUri,
    driveFolderId,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadJob &&
          other.id == this.id &&
          other.recordingId == this.recordingId &&
          other.kind == this.kind &&
          other.state == this.state &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.resumableUri == this.resumableUri &&
          other.driveFolderId == this.driveFolderId &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UploadJobsCompanion extends UpdateCompanion<UploadJob> {
  final Value<String> id;
  final Value<String> recordingId;
  final Value<UploadJobKind> kind;
  final Value<UploadJobState> state;
  final Value<int> retryCount;
  final Value<String?> nextRetryAt;
  final Value<String?> resumableUri;
  final Value<String?> driveFolderId;
  final Value<String?> lastError;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const UploadJobsCompanion({
    this.id = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.kind = const Value.absent(),
    this.state = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.resumableUri = const Value.absent(),
    this.driveFolderId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UploadJobsCompanion.insert({
    required String id,
    required String recordingId,
    required UploadJobKind kind,
    this.state = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.resumableUri = const Value.absent(),
    this.driveFolderId = const Value.absent(),
    this.lastError = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordingId = Value(recordingId),
       kind = Value(kind),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UploadJob> custom({
    Expression<String>? id,
    Expression<String>? recordingId,
    Expression<String>? kind,
    Expression<String>? state,
    Expression<int>? retryCount,
    Expression<String>? nextRetryAt,
    Expression<String>? resumableUri,
    Expression<String>? driveFolderId,
    Expression<String>? lastError,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordingId != null) 'recording_id': recordingId,
      if (kind != null) 'kind': kind,
      if (state != null) 'state': state,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (resumableUri != null) 'resumable_uri': resumableUri,
      if (driveFolderId != null) 'drive_folder_id': driveFolderId,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UploadJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? recordingId,
    Value<UploadJobKind>? kind,
    Value<UploadJobState>? state,
    Value<int>? retryCount,
    Value<String?>? nextRetryAt,
    Value<String?>? resumableUri,
    Value<String?>? driveFolderId,
    Value<String?>? lastError,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return UploadJobsCompanion(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      kind: kind ?? this.kind,
      state: state ?? this.state,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      resumableUri: resumableUri ?? this.resumableUri,
      driveFolderId: driveFolderId ?? this.driveFolderId,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<String>(recordingId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $UploadJobsTable.$converterkind.toSql(kind.value),
      );
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $UploadJobsTable.$converterstate.toSql(state.value),
      );
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<String>(nextRetryAt.value);
    }
    if (resumableUri.present) {
      map['resumable_uri'] = Variable<String>(resumableUri.value);
    }
    if (driveFolderId.present) {
      map['drive_folder_id'] = Variable<String>(driveFolderId.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadJobsCompanion(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('kind: $kind, ')
          ..write('state: $state, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('resumableUri: $resumableUri, ')
          ..write('driveFolderId: $driveFolderId, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranscriptionJobsTable extends TranscriptionJobs
    with TableInfo<$TranscriptionJobsTable, TranscriptionJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptionJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<String> recordingId = GeneratedColumn<String>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recordings (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _engineIdMeta = const VerificationMeta(
    'engineId',
  );
  @override
  late final GeneratedColumn<String> engineId = GeneratedColumn<String>(
    'engine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobHandleMeta = const VerificationMeta(
    'jobHandle',
  );
  @override
  late final GeneratedColumn<String> jobHandle = GeneratedColumn<String>(
    'job_handle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TranscriptionJobState, String>
  state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('queued'),
      ).withConverter<TranscriptionJobState>(
        $TranscriptionJobsTable.$converterstate,
      );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localeIdMeta = const VerificationMeta(
    'localeId',
  );
  @override
  late final GeneratedColumn<String> localeId = GeneratedColumn<String>(
    'locale_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordingId,
    engineId,
    jobHandle,
    state,
    attempt,
    localeId,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcription_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranscriptionJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('engine_id')) {
      context.handle(
        _engineIdMeta,
        engineId.isAcceptableOrUnknown(data['engine_id']!, _engineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_engineIdMeta);
    }
    if (data.containsKey('job_handle')) {
      context.handle(
        _jobHandleMeta,
        jobHandle.isAcceptableOrUnknown(data['job_handle']!, _jobHandleMeta),
      );
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    }
    if (data.containsKey('locale_id')) {
      context.handle(
        _localeIdMeta,
        localeId.isAcceptableOrUnknown(data['locale_id']!, _localeIdMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TranscriptionJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranscriptionJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_id'],
      )!,
      engineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine_id'],
      )!,
      jobHandle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_handle'],
      ),
      state: $TranscriptionJobsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt'],
      )!,
      localeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_id'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TranscriptionJobsTable createAlias(String alias) {
    return $TranscriptionJobsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TranscriptionJobState, String, String>
  $converterstate = const EnumNameConverter<TranscriptionJobState>(
    TranscriptionJobState.values,
  );
}

class TranscriptionJob extends DataClass
    implements Insertable<TranscriptionJob> {
  /// UUID。
  final String id;

  /// 対象録音（FK → recordings.id）。
  final String recordingId;

  /// cloud_stt 等。Registry のキー。
  final String engineId;

  /// エンジン固有のジョブ識別子を JSON 文字列でシリアライズ保存。再購読に必須。
  final String? jobHandle;

  /// ジョブ状態。
  final TranscriptionJobState state;

  /// 試行回数。
  final int attempt;

  /// ジョブ投入時点の言語設定（ja-JP 等）。autoDetect エンジンは NULL。
  final String? localeId;

  /// 直近エラー（機微情報を含めない）。
  final String? lastError;
  final String createdAt;
  final String updatedAt;
  const TranscriptionJob({
    required this.id,
    required this.recordingId,
    required this.engineId,
    this.jobHandle,
    required this.state,
    required this.attempt,
    this.localeId,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recording_id'] = Variable<String>(recordingId);
    map['engine_id'] = Variable<String>(engineId);
    if (!nullToAbsent || jobHandle != null) {
      map['job_handle'] = Variable<String>(jobHandle);
    }
    {
      map['state'] = Variable<String>(
        $TranscriptionJobsTable.$converterstate.toSql(state),
      );
    }
    map['attempt'] = Variable<int>(attempt);
    if (!nullToAbsent || localeId != null) {
      map['locale_id'] = Variable<String>(localeId);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TranscriptionJobsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptionJobsCompanion(
      id: Value(id),
      recordingId: Value(recordingId),
      engineId: Value(engineId),
      jobHandle: jobHandle == null && nullToAbsent
          ? const Value.absent()
          : Value(jobHandle),
      state: Value(state),
      attempt: Value(attempt),
      localeId: localeId == null && nullToAbsent
          ? const Value.absent()
          : Value(localeId),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TranscriptionJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranscriptionJob(
      id: serializer.fromJson<String>(json['id']),
      recordingId: serializer.fromJson<String>(json['recordingId']),
      engineId: serializer.fromJson<String>(json['engineId']),
      jobHandle: serializer.fromJson<String?>(json['jobHandle']),
      state: $TranscriptionJobsTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      attempt: serializer.fromJson<int>(json['attempt']),
      localeId: serializer.fromJson<String?>(json['localeId']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordingId': serializer.toJson<String>(recordingId),
      'engineId': serializer.toJson<String>(engineId),
      'jobHandle': serializer.toJson<String?>(jobHandle),
      'state': serializer.toJson<String>(
        $TranscriptionJobsTable.$converterstate.toJson(state),
      ),
      'attempt': serializer.toJson<int>(attempt),
      'localeId': serializer.toJson<String?>(localeId),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  TranscriptionJob copyWith({
    String? id,
    String? recordingId,
    String? engineId,
    Value<String?> jobHandle = const Value.absent(),
    TranscriptionJobState? state,
    int? attempt,
    Value<String?> localeId = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => TranscriptionJob(
    id: id ?? this.id,
    recordingId: recordingId ?? this.recordingId,
    engineId: engineId ?? this.engineId,
    jobHandle: jobHandle.present ? jobHandle.value : this.jobHandle,
    state: state ?? this.state,
    attempt: attempt ?? this.attempt,
    localeId: localeId.present ? localeId.value : this.localeId,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TranscriptionJob copyWithCompanion(TranscriptionJobsCompanion data) {
    return TranscriptionJob(
      id: data.id.present ? data.id.value : this.id,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      engineId: data.engineId.present ? data.engineId.value : this.engineId,
      jobHandle: data.jobHandle.present ? data.jobHandle.value : this.jobHandle,
      state: data.state.present ? data.state.value : this.state,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      localeId: data.localeId.present ? data.localeId.value : this.localeId,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptionJob(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('engineId: $engineId, ')
          ..write('jobHandle: $jobHandle, ')
          ..write('state: $state, ')
          ..write('attempt: $attempt, ')
          ..write('localeId: $localeId, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordingId,
    engineId,
    jobHandle,
    state,
    attempt,
    localeId,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptionJob &&
          other.id == this.id &&
          other.recordingId == this.recordingId &&
          other.engineId == this.engineId &&
          other.jobHandle == this.jobHandle &&
          other.state == this.state &&
          other.attempt == this.attempt &&
          other.localeId == this.localeId &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TranscriptionJobsCompanion extends UpdateCompanion<TranscriptionJob> {
  final Value<String> id;
  final Value<String> recordingId;
  final Value<String> engineId;
  final Value<String?> jobHandle;
  final Value<TranscriptionJobState> state;
  final Value<int> attempt;
  final Value<String?> localeId;
  final Value<String?> lastError;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const TranscriptionJobsCompanion({
    this.id = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.engineId = const Value.absent(),
    this.jobHandle = const Value.absent(),
    this.state = const Value.absent(),
    this.attempt = const Value.absent(),
    this.localeId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptionJobsCompanion.insert({
    required String id,
    required String recordingId,
    required String engineId,
    this.jobHandle = const Value.absent(),
    this.state = const Value.absent(),
    this.attempt = const Value.absent(),
    this.localeId = const Value.absent(),
    this.lastError = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordingId = Value(recordingId),
       engineId = Value(engineId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TranscriptionJob> custom({
    Expression<String>? id,
    Expression<String>? recordingId,
    Expression<String>? engineId,
    Expression<String>? jobHandle,
    Expression<String>? state,
    Expression<int>? attempt,
    Expression<String>? localeId,
    Expression<String>? lastError,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordingId != null) 'recording_id': recordingId,
      if (engineId != null) 'engine_id': engineId,
      if (jobHandle != null) 'job_handle': jobHandle,
      if (state != null) 'state': state,
      if (attempt != null) 'attempt': attempt,
      if (localeId != null) 'locale_id': localeId,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptionJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? recordingId,
    Value<String>? engineId,
    Value<String?>? jobHandle,
    Value<TranscriptionJobState>? state,
    Value<int>? attempt,
    Value<String?>? localeId,
    Value<String?>? lastError,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return TranscriptionJobsCompanion(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      engineId: engineId ?? this.engineId,
      jobHandle: jobHandle ?? this.jobHandle,
      state: state ?? this.state,
      attempt: attempt ?? this.attempt,
      localeId: localeId ?? this.localeId,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<String>(recordingId.value);
    }
    if (engineId.present) {
      map['engine_id'] = Variable<String>(engineId.value);
    }
    if (jobHandle.present) {
      map['job_handle'] = Variable<String>(jobHandle.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $TranscriptionJobsTable.$converterstate.toSql(state.value),
      );
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (localeId.present) {
      map['locale_id'] = Variable<String>(localeId.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptionJobsCompanion(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('engineId: $engineId, ')
          ..write('jobHandle: $jobHandle, ')
          ..write('state: $state, ')
          ..write('attempt: $attempt, ')
          ..write('localeId: $localeId, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingEntry extends DataClass implements Insertable<SettingEntry> {
  final String key;
  final String? value;
  const SettingEntry({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory SettingEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  SettingEntry copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => SettingEntry(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  SettingEntry copyWithCompanion(SettingsTableCompanion data) {
    return SettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsTableCompanion extends UpdateCompanion<SettingEntry> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SettingEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecordingsTable recordings = $RecordingsTable(this);
  late final $UploadJobsTable uploadJobs = $UploadJobsTable(this);
  late final $TranscriptionJobsTable transcriptionJobs =
      $TranscriptionJobsTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final RecordingsDao recordingsDao = RecordingsDao(this as AppDatabase);
  late final UploadJobsDao uploadJobsDao = UploadJobsDao(this as AppDatabase);
  late final TranscriptionJobsDao transcriptionJobsDao = TranscriptionJobsDao(
    this as AppDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    recordings,
    uploadJobs,
    transcriptionJobs,
    settingsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recordings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('upload_jobs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recordings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transcription_jobs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$RecordingsTableCreateCompanionBuilder =
    RecordingsCompanion Function({
      required String id,
      required String startedAt,
      Value<int> durationMs,
      Value<String?> localPath,
      Value<String> title,
      Value<String?> driveFileId,
      Value<String?> txtDriveFileId,
      Value<UploadState> uploadState,
      Value<TranscriptState> transcriptState,
      Value<int> sizeBytes,
      required Codec codec,
      Value<String?> transcriptLocalPath,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$RecordingsTableUpdateCompanionBuilder =
    RecordingsCompanion Function({
      Value<String> id,
      Value<String> startedAt,
      Value<int> durationMs,
      Value<String?> localPath,
      Value<String> title,
      Value<String?> driveFileId,
      Value<String?> txtDriveFileId,
      Value<UploadState> uploadState,
      Value<TranscriptState> transcriptState,
      Value<int> sizeBytes,
      Value<Codec> codec,
      Value<String?> transcriptLocalPath,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$RecordingsTableReferences
    extends BaseReferences<_$AppDatabase, $RecordingsTable, Recording> {
  $$RecordingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UploadJobsTable, List<UploadJob>>
  _uploadJobsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.uploadJobs,
    aliasName: $_aliasNameGenerator(
      db.recordings.id,
      db.uploadJobs.recordingId,
    ),
  );

  $$UploadJobsTableProcessedTableManager get uploadJobsRefs {
    final manager = $$UploadJobsTableTableManager(
      $_db,
      $_db.uploadJobs,
    ).filter((f) => f.recordingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_uploadJobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TranscriptionJobsTable, List<TranscriptionJob>>
  _transcriptionJobsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transcriptionJobs,
        aliasName: $_aliasNameGenerator(
          db.recordings.id,
          db.transcriptionJobs.recordingId,
        ),
      );

  $$TranscriptionJobsTableProcessedTableManager get transcriptionJobsRefs {
    final manager = $$TranscriptionJobsTableTableManager(
      $_db,
      $_db.transcriptionJobs,
    ).filter((f) => f.recordingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transcriptionJobsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get txtDriveFileId => $composableBuilder(
    column: $table.txtDriveFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<UploadState, UploadState, String>
  get uploadState => $composableBuilder(
    column: $table.uploadState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TranscriptState, TranscriptState, String>
  get transcriptState => $composableBuilder(
    column: $table.transcriptState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Codec, Codec, String> get codec =>
      $composableBuilder(
        column: $table.codec,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get transcriptLocalPath => $composableBuilder(
    column: $table.transcriptLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> uploadJobsRefs(
    Expression<bool> Function($$UploadJobsTableFilterComposer f) f,
  ) {
    final $$UploadJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.uploadJobs,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UploadJobsTableFilterComposer(
            $db: $db,
            $table: $db.uploadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transcriptionJobsRefs(
    Expression<bool> Function($$TranscriptionJobsTableFilterComposer f) f,
  ) {
    final $$TranscriptionJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transcriptionJobs,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranscriptionJobsTableFilterComposer(
            $db: $db,
            $table: $db.transcriptionJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get txtDriveFileId => $composableBuilder(
    column: $table.txtDriveFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadState => $composableBuilder(
    column: $table.uploadState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcriptState => $composableBuilder(
    column: $table.transcriptState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcriptLocalPath => $composableBuilder(
    column: $table.transcriptLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get driveFileId => $composableBuilder(
    column: $table.driveFileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get txtDriveFileId => $composableBuilder(
    column: $table.txtDriveFileId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<UploadState, String> get uploadState =>
      $composableBuilder(
        column: $table.uploadState,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<TranscriptState, String>
  get transcriptState => $composableBuilder(
    column: $table.transcriptState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Codec, String> get codec =>
      $composableBuilder(column: $table.codec, builder: (column) => column);

  GeneratedColumn<String> get transcriptLocalPath => $composableBuilder(
    column: $table.transcriptLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> uploadJobsRefs<T extends Object>(
    Expression<T> Function($$UploadJobsTableAnnotationComposer a) f,
  ) {
    final $$UploadJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.uploadJobs,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UploadJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.uploadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transcriptionJobsRefs<T extends Object>(
    Expression<T> Function($$TranscriptionJobsTableAnnotationComposer a) f,
  ) {
    final $$TranscriptionJobsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transcriptionJobs,
          getReferencedColumn: (t) => t.recordingId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TranscriptionJobsTableAnnotationComposer(
                $db: $db,
                $table: $db.transcriptionJobs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordingsTable,
          Recording,
          $$RecordingsTableFilterComposer,
          $$RecordingsTableOrderingComposer,
          $$RecordingsTableAnnotationComposer,
          $$RecordingsTableCreateCompanionBuilder,
          $$RecordingsTableUpdateCompanionBuilder,
          (Recording, $$RecordingsTableReferences),
          Recording,
          PrefetchHooks Function({
            bool uploadJobsRefs,
            bool transcriptionJobsRefs,
          })
        > {
  $$RecordingsTableTableManager(_$AppDatabase db, $RecordingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> driveFileId = const Value.absent(),
                Value<String?> txtDriveFileId = const Value.absent(),
                Value<UploadState> uploadState = const Value.absent(),
                Value<TranscriptState> transcriptState = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<Codec> codec = const Value.absent(),
                Value<String?> transcriptLocalPath = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordingsCompanion(
                id: id,
                startedAt: startedAt,
                durationMs: durationMs,
                localPath: localPath,
                title: title,
                driveFileId: driveFileId,
                txtDriveFileId: txtDriveFileId,
                uploadState: uploadState,
                transcriptState: transcriptState,
                sizeBytes: sizeBytes,
                codec: codec,
                transcriptLocalPath: transcriptLocalPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String startedAt,
                Value<int> durationMs = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> driveFileId = const Value.absent(),
                Value<String?> txtDriveFileId = const Value.absent(),
                Value<UploadState> uploadState = const Value.absent(),
                Value<TranscriptState> transcriptState = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                required Codec codec,
                Value<String?> transcriptLocalPath = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RecordingsCompanion.insert(
                id: id,
                startedAt: startedAt,
                durationMs: durationMs,
                localPath: localPath,
                title: title,
                driveFileId: driveFileId,
                txtDriveFileId: txtDriveFileId,
                uploadState: uploadState,
                transcriptState: transcriptState,
                sizeBytes: sizeBytes,
                codec: codec,
                transcriptLocalPath: transcriptLocalPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecordingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({uploadJobsRefs = false, transcriptionJobsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (uploadJobsRefs) db.uploadJobs,
                    if (transcriptionJobsRefs) db.transcriptionJobs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (uploadJobsRefs)
                        await $_getPrefetchedData<
                          Recording,
                          $RecordingsTable,
                          UploadJob
                        >(
                          currentTable: table,
                          referencedTable: $$RecordingsTableReferences
                              ._uploadJobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordingsTableReferences(
                                db,
                                table,
                                p0,
                              ).uploadJobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordingId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transcriptionJobsRefs)
                        await $_getPrefetchedData<
                          Recording,
                          $RecordingsTable,
                          TranscriptionJob
                        >(
                          currentTable: table,
                          referencedTable: $$RecordingsTableReferences
                              ._transcriptionJobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordingsTableReferences(
                                db,
                                table,
                                p0,
                              ).transcriptionJobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordingId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordingsTable,
      Recording,
      $$RecordingsTableFilterComposer,
      $$RecordingsTableOrderingComposer,
      $$RecordingsTableAnnotationComposer,
      $$RecordingsTableCreateCompanionBuilder,
      $$RecordingsTableUpdateCompanionBuilder,
      (Recording, $$RecordingsTableReferences),
      Recording,
      PrefetchHooks Function({bool uploadJobsRefs, bool transcriptionJobsRefs})
    >;
typedef $$UploadJobsTableCreateCompanionBuilder =
    UploadJobsCompanion Function({
      required String id,
      required String recordingId,
      required UploadJobKind kind,
      Value<UploadJobState> state,
      Value<int> retryCount,
      Value<String?> nextRetryAt,
      Value<String?> resumableUri,
      Value<String?> driveFolderId,
      Value<String?> lastError,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$UploadJobsTableUpdateCompanionBuilder =
    UploadJobsCompanion Function({
      Value<String> id,
      Value<String> recordingId,
      Value<UploadJobKind> kind,
      Value<UploadJobState> state,
      Value<int> retryCount,
      Value<String?> nextRetryAt,
      Value<String?> resumableUri,
      Value<String?> driveFolderId,
      Value<String?> lastError,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$UploadJobsTableReferences
    extends BaseReferences<_$AppDatabase, $UploadJobsTable, UploadJob> {
  $$UploadJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecordingsTable _recordingIdTable(_$AppDatabase db) =>
      db.recordings.createAlias(
        $_aliasNameGenerator(db.uploadJobs.recordingId, db.recordings.id),
      );

  $$RecordingsTableProcessedTableManager get recordingId {
    final $_column = $_itemColumn<String>('recording_id')!;

    final manager = $$RecordingsTableTableManager(
      $_db,
      $_db.recordings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UploadJobsTableFilterComposer
    extends Composer<_$AppDatabase, $UploadJobsTable> {
  $$UploadJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<UploadJobKind, UploadJobKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<UploadJobState, UploadJobState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumableUri => $composableBuilder(
    column: $table.resumableUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driveFolderId => $composableBuilder(
    column: $table.driveFolderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordingsTableFilterComposer get recordingId {
    final $$RecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableFilterComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UploadJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadJobsTable> {
  $$UploadJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumableUri => $composableBuilder(
    column: $table.resumableUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driveFolderId => $composableBuilder(
    column: $table.driveFolderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordingsTableOrderingComposer get recordingId {
    final $$RecordingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableOrderingComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UploadJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadJobsTable> {
  $$UploadJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UploadJobKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UploadJobState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resumableUri => $composableBuilder(
    column: $table.resumableUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get driveFolderId => $composableBuilder(
    column: $table.driveFolderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RecordingsTableAnnotationComposer get recordingId {
    final $$RecordingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableAnnotationComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UploadJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UploadJobsTable,
          UploadJob,
          $$UploadJobsTableFilterComposer,
          $$UploadJobsTableOrderingComposer,
          $$UploadJobsTableAnnotationComposer,
          $$UploadJobsTableCreateCompanionBuilder,
          $$UploadJobsTableUpdateCompanionBuilder,
          (UploadJob, $$UploadJobsTableReferences),
          UploadJob,
          PrefetchHooks Function({bool recordingId})
        > {
  $$UploadJobsTableTableManager(_$AppDatabase db, $UploadJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recordingId = const Value.absent(),
                Value<UploadJobKind> kind = const Value.absent(),
                Value<UploadJobState> state = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> nextRetryAt = const Value.absent(),
                Value<String?> resumableUri = const Value.absent(),
                Value<String?> driveFolderId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UploadJobsCompanion(
                id: id,
                recordingId: recordingId,
                kind: kind,
                state: state,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                resumableUri: resumableUri,
                driveFolderId: driveFolderId,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recordingId,
                required UploadJobKind kind,
                Value<UploadJobState> state = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> nextRetryAt = const Value.absent(),
                Value<String?> resumableUri = const Value.absent(),
                Value<String?> driveFolderId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UploadJobsCompanion.insert(
                id: id,
                recordingId: recordingId,
                kind: kind,
                state: state,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                resumableUri: resumableUri,
                driveFolderId: driveFolderId,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UploadJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordingId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordingId,
                                referencedTable: $$UploadJobsTableReferences
                                    ._recordingIdTable(db),
                                referencedColumn: $$UploadJobsTableReferences
                                    ._recordingIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UploadJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UploadJobsTable,
      UploadJob,
      $$UploadJobsTableFilterComposer,
      $$UploadJobsTableOrderingComposer,
      $$UploadJobsTableAnnotationComposer,
      $$UploadJobsTableCreateCompanionBuilder,
      $$UploadJobsTableUpdateCompanionBuilder,
      (UploadJob, $$UploadJobsTableReferences),
      UploadJob,
      PrefetchHooks Function({bool recordingId})
    >;
typedef $$TranscriptionJobsTableCreateCompanionBuilder =
    TranscriptionJobsCompanion Function({
      required String id,
      required String recordingId,
      required String engineId,
      Value<String?> jobHandle,
      Value<TranscriptionJobState> state,
      Value<int> attempt,
      Value<String?> localeId,
      Value<String?> lastError,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$TranscriptionJobsTableUpdateCompanionBuilder =
    TranscriptionJobsCompanion Function({
      Value<String> id,
      Value<String> recordingId,
      Value<String> engineId,
      Value<String?> jobHandle,
      Value<TranscriptionJobState> state,
      Value<int> attempt,
      Value<String?> localeId,
      Value<String?> lastError,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$TranscriptionJobsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TranscriptionJobsTable,
          TranscriptionJob
        > {
  $$TranscriptionJobsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecordingsTable _recordingIdTable(_$AppDatabase db) =>
      db.recordings.createAlias(
        $_aliasNameGenerator(
          db.transcriptionJobs.recordingId,
          db.recordings.id,
        ),
      );

  $$RecordingsTableProcessedTableManager get recordingId {
    final $_column = $_itemColumn<String>('recording_id')!;

    final manager = $$RecordingsTableTableManager(
      $_db,
      $_db.recordings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TranscriptionJobsTableFilterComposer
    extends Composer<_$AppDatabase, $TranscriptionJobsTable> {
  $$TranscriptionJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engineId => $composableBuilder(
    column: $table.engineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobHandle => $composableBuilder(
    column: $table.jobHandle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    TranscriptionJobState,
    TranscriptionJobState,
    String
  >
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeId => $composableBuilder(
    column: $table.localeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordingsTableFilterComposer get recordingId {
    final $$RecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableFilterComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptionJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranscriptionJobsTable> {
  $$TranscriptionJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engineId => $composableBuilder(
    column: $table.engineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobHandle => $composableBuilder(
    column: $table.jobHandle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeId => $composableBuilder(
    column: $table.localeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordingsTableOrderingComposer get recordingId {
    final $$RecordingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableOrderingComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptionJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranscriptionJobsTable> {
  $$TranscriptionJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get engineId =>
      $composableBuilder(column: $table.engineId, builder: (column) => column);

  GeneratedColumn<String> get jobHandle =>
      $composableBuilder(column: $table.jobHandle, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TranscriptionJobState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<String> get localeId =>
      $composableBuilder(column: $table.localeId, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RecordingsTableAnnotationComposer get recordingId {
    final $$RecordingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableAnnotationComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptionJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranscriptionJobsTable,
          TranscriptionJob,
          $$TranscriptionJobsTableFilterComposer,
          $$TranscriptionJobsTableOrderingComposer,
          $$TranscriptionJobsTableAnnotationComposer,
          $$TranscriptionJobsTableCreateCompanionBuilder,
          $$TranscriptionJobsTableUpdateCompanionBuilder,
          (TranscriptionJob, $$TranscriptionJobsTableReferences),
          TranscriptionJob,
          PrefetchHooks Function({bool recordingId})
        > {
  $$TranscriptionJobsTableTableManager(
    _$AppDatabase db,
    $TranscriptionJobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptionJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranscriptionJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranscriptionJobsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recordingId = const Value.absent(),
                Value<String> engineId = const Value.absent(),
                Value<String?> jobHandle = const Value.absent(),
                Value<TranscriptionJobState> state = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<String?> localeId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranscriptionJobsCompanion(
                id: id,
                recordingId: recordingId,
                engineId: engineId,
                jobHandle: jobHandle,
                state: state,
                attempt: attempt,
                localeId: localeId,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recordingId,
                required String engineId,
                Value<String?> jobHandle = const Value.absent(),
                Value<TranscriptionJobState> state = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<String?> localeId = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TranscriptionJobsCompanion.insert(
                id: id,
                recordingId: recordingId,
                engineId: engineId,
                jobHandle: jobHandle,
                state: state,
                attempt: attempt,
                localeId: localeId,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TranscriptionJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordingId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordingId,
                                referencedTable:
                                    $$TranscriptionJobsTableReferences
                                        ._recordingIdTable(db),
                                referencedColumn:
                                    $$TranscriptionJobsTableReferences
                                        ._recordingIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TranscriptionJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranscriptionJobsTable,
      TranscriptionJob,
      $$TranscriptionJobsTableFilterComposer,
      $$TranscriptionJobsTableOrderingComposer,
      $$TranscriptionJobsTableAnnotationComposer,
      $$TranscriptionJobsTableCreateCompanionBuilder,
      $$TranscriptionJobsTableUpdateCompanionBuilder,
      (TranscriptionJob, $$TranscriptionJobsTableReferences),
      TranscriptionJob,
      PrefetchHooks Function({bool recordingId})
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingEntry,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingEntry,
            BaseReferences<_$AppDatabase, $SettingsTableTable, SettingEntry>,
          ),
          SettingEntry,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SettingsTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingEntry,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingEntry,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingEntry>,
      ),
      SettingEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db, _db.recordings);
  $$UploadJobsTableTableManager get uploadJobs =>
      $$UploadJobsTableTableManager(_db, _db.uploadJobs);
  $$TranscriptionJobsTableTableManager get transcriptionJobs =>
      $$TranscriptionJobsTableTableManager(_db, _db.transcriptionJobs);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}

mixin _$RecordingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecordingsTable get recordings => attachedDatabase.recordings;
  RecordingsDaoManager get managers => RecordingsDaoManager(this);
}

class RecordingsDaoManager {
  final _$RecordingsDaoMixin _db;
  RecordingsDaoManager(this._db);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
}

mixin _$UploadJobsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecordingsTable get recordings => attachedDatabase.recordings;
  $UploadJobsTable get uploadJobs => attachedDatabase.uploadJobs;
  UploadJobsDaoManager get managers => UploadJobsDaoManager(this);
}

class UploadJobsDaoManager {
  final _$UploadJobsDaoMixin _db;
  UploadJobsDaoManager(this._db);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
  $$UploadJobsTableTableManager get uploadJobs =>
      $$UploadJobsTableTableManager(_db.attachedDatabase, _db.uploadJobs);
}

mixin _$TranscriptionJobsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecordingsTable get recordings => attachedDatabase.recordings;
  $TranscriptionJobsTable get transcriptionJobs =>
      attachedDatabase.transcriptionJobs;
  TranscriptionJobsDaoManager get managers => TranscriptionJobsDaoManager(this);
}

class TranscriptionJobsDaoManager {
  final _$TranscriptionJobsDaoMixin _db;
  TranscriptionJobsDaoManager(this._db);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
  $$TranscriptionJobsTableTableManager get transcriptionJobs =>
      $$TranscriptionJobsTableTableManager(
        _db.attachedDatabase,
        _db.transcriptionJobs,
      );
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTableTable get settingsTable => attachedDatabase.settingsTable;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db.attachedDatabase, _db.settingsTable);
}
