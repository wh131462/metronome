import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:args/args.dart';

// 构建配置
class BuildConfig {
  final bool incrementVersion;
  final bool skipClean;
  final bool verbose;
  final String buildType;
  final String? outputDir;

  BuildConfig({
    this.incrementVersion = false,
    this.skipClean = false,
    this.verbose = false,
    this.buildType = 'release',
    this.outputDir,
  });
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('increment-version', abbr: 'i', 
        help: '自动增加版本号')
    ..addFlag('skip-clean', 
        help: '跳过清理步骤')
    ..addFlag('verbose', abbr: 'v', 
        help: '显示详细日志')
    ..addOption('build-type', 
        allowed: ['release', 'debug'], 
        defaultsTo: 'release',
        help: '构建类型')
    ..addOption('output-dir', 
        help: '指定输出目录');

  try {
    final results = parser.parse(arguments);
    final config = BuildConfig(
      incrementVersion: results['increment-version'],
      skipClean: results['skip-clean'],
      verbose: results['verbose'],
      buildType: results['build-type'],
      outputDir: results['output-dir'],
    );

    await build(config);
  } catch (e) {
    print('错误: $e');
    print('\n使用方法:\n${parser.usage}');
    exit(1);
  }
}

Future<void> build(BuildConfig config) async {
  final logger = Logger(verbose: config.verbose);
  final DateTime startTime = DateTime.now();

  try {
    // 获取项目目录 - 修复目录获取逻辑
    final scriptDir = Directory.current;
    final projectDir = scriptDir.path.endsWith('scripts') 
        ? scriptDir.parent 
        : scriptDir;  // 如果当前目录是 scripts，则返回父目录，否则使用当前目录

    logger.log('项目目录: ${projectDir.path}');

    // 设置输出目录
    final releaseDir = Directory(
      config.outputDir ?? path.join(projectDir.path, 'release')
    );
    if (!await releaseDir.exists()) {
      await releaseDir.create(recursive: true);
    }

    // 读取并更新版本号
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw '未找到 pubspec.yaml 文件，请确保在项目根目录或 scripts 目录下运行此脚本';
    }

    var version = await _getVersion(pubspecFile);
    
    if (config.incrementVersion) {
      version = await _incrementVersion(pubspecFile, version);
      logger.log('版本号已更新为: $version');
    }

    logger.log('开始构建版本: $version');

    // 执行构建命令
    if (!config.skipClean) {
      await _runCommand('flutter', ['clean'], logger);
      logger.log('清理完成');
    }

    await _runCommand('flutter', ['pub', 'get'], logger);
    logger.log('依赖更新完成');

    final buildArgs = ['build', 'apk', '--${config.buildType}'];
    await _runCommand('flutter', buildArgs, logger);
    logger.log('APK 构建完成');

    // 移动并重命名 APK
    final buildApk = File(path.join(
      projectDir.path,
      'build',
      'app',
      'outputs',
      'flutter-apk',
      'app-${config.buildType}.apk',
    ));

    final targetApk = File(path.join(
      releaseDir.path,
      'metronome-$version.apk',
    ));

    await buildApk.copy(targetApk.path);
    logger.log('APK 已移动到: ${targetApk.path}');

    // 记录构建日志
    await _saveBuildLog(releaseDir.path, logger, startTime);

    // 打开输出目录
    await _openDirectory(releaseDir.path);

    logger.log('构建完成!');
  } catch (e) {
    logger.error('构建失败: $e');
    // 确保日志目录存在
    final logDir = Directory(config.outputDir ?? 'release');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    await _saveBuildLog(logDir.path, logger, startTime);
    exit(1);
  }
}

Future<String> _getVersion(File pubspecFile) async {
  final content = await pubspecFile.readAsString();
  final pubspec = loadYaml(content);
  return pubspec['version'].toString().split('+')[0];
}

Future<String> _incrementVersion(File pubspecFile, String currentVersion) async {
  final parts = currentVersion.split('.');
  final patch = int.parse(parts[2]) + 1;
  final newVersion = '${parts[0]}.${parts[1]}.$patch';

  final content = await pubspecFile.readAsString();
  final newContent = content.replaceFirst(
    RegExp(r'version: .*'),
    'version: $newVersion+${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
  );

  await pubspecFile.writeAsString(newContent);
  return newVersion;
}

Future<void> _saveBuildLog(String dir, Logger logger, DateTime startTime) async {
  final duration = DateTime.now().difference(startTime);
  final logFile = File(path.join(dir, 'build_${DateTime.now().toIso8601String()}.log'));
  await logFile.writeAsString(
    '构建日志\n'
    '开始时间: $startTime\n'
    '结束时间: ${DateTime.now()}\n'
    '耗时: ${duration.inSeconds} 秒\n\n'
    '${logger.getFullLog()}'
  );
}

class Logger {
  final bool verbose;
  final List<String> _logs = [];

  Logger({this.verbose = false});

  void log(String message) {
    _logs.add('[${DateTime.now()}] $message');
    if (verbose) {
      print(message);
    } else {
      print('> $message');
    }
  }

  void error(String message) {
    _logs.add('[${DateTime.now()}] ERROR: $message');
    print('\x1B[31m错误: $message\x1B[0m');
  }

  String getFullLog() => _logs.join('\n');
}

Future<void> _runCommand(String command, List<String> arguments, Logger logger) async {
  logger.log('执行命令: $command ${arguments.join(' ')}');
  
  final result = await Process.run(command, arguments);
  if (result.exitCode != 0) {
    final error = '命令执行失败: $command ${arguments.join(' ')}\n${result.stderr}';
    logger.error(error);
    throw error;
  }

  if (result.stdout.toString().isNotEmpty) {
    logger.log('输出: ${result.stdout}');
  }
}

Future<void> _openDirectory(String path) async {
  if (Platform.isWindows) {
    await Process.run('explorer', [path]);
  } else if (Platform.isMacOS) {
    await Process.run('open', [path]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [path]);
  }
}

// 添加一个辅助方法来验证目录
bool _isProjectRoot(String dir) {
  return File(path.join(dir, 'pubspec.yaml')).existsSync();
} 