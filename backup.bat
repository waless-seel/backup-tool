@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ==============================================
:: Windows Automated Backup Script
:: ==============================================

:: 設定セクション - 必要に応じて編集してください

:: バックアップ対象フォルダ（複数指定可能、スペース区切り）
set SOURCE_DRIVE=C:
set SOURCE_DIRS=Users\%USERNAME%\home Users\%USERNAME%\Pictures Users\%USERNAME%\Videos Users\%USERNAME%\Music MO2

set BACKUP_DRIVE=D:
set BACKUP_ROOT_DIR=Backup
set BACKUP_BASE_DIR=%BACKUP_DRIVE%\%BACKUP_ROOT_DIR%

:: 除外フォルダ（robocopy の /XD オプション用、スペース区切り）
set EXCLUDE_DIRS=temp tmp cache node_modules .git __pycache__ GoogleDrive GooglePhoto DMMGamePlayer

:: 除外ファイル（robocopy の /XF オプション用、スペース区切り）
set EXCLUDE_FILES=*.temp *.tmp *.log thumbs.db desktop.ini

:: ログファイル
set LOG_FILE=%BACKUP_BASE_DIR%\backup_log.txt

:: 日時取得（YYYY-MM-DD_HH-MM-SS 形式、WMIC 不要）
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "timestamp=%%a"

:: バックアップディレクトリ作成
set BACKUP_DIR=%BACKUP_BASE_DIR%
if not exist "%BACKUP_BASE_DIR%" mkdir "%BACKUP_BASE_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: ログ開始
echo ======================================== >> "%LOG_FILE%"
echo バックアップ開始: %timestamp% >> "%LOG_FILE%"
echo バックアップ対象: %SOURCE_DIRS% >> "%LOG_FILE%"
echo バックアップ先: %BACKUP_DIR% >> "%LOG_FILE%"
echo 除外フォルダ: %EXCLUDE_DIRS% >> "%LOG_FILE%"
echo 除外ファイル: %EXCLUDE_FILES% >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"

echo バックアップを開始します...
echo バックアップ対象: %SOURCE_DIRS%
echo バックアップ先: %BACKUP_DIR%
echo 除外フォルダ: %EXCLUDE_DIRS%
echo 除外ファイル: %EXCLUDE_FILES%
echo.

set OVERALL_RESULT=0

:: 複数のソースディレクトリを処理
for %%S in (%SOURCE_DIRS%) do (
    set CURRENT_SOURCE=%%~S
    set CURRENT_SOURCE_DIR=!SOURCE_DRIVE!\!CURRENT_SOURCE!
    if exist "!CURRENT_SOURCE_DIR!" (
        echo [ソースディレクトリ] !CURRENT_SOURCE!
        echo [ソースフォルダ] !CURRENT_SOURCE_DIR!
        echo [ソースフォルダ] !CURRENT_SOURCE_DIR! >> "%LOG_FILE%"
        
        :: ソースフォルダの階層を保持してバックアップ先に追加
        set "DEST_PATH=!BACKUP_DIR!\!CURRENT_SOURCE!"
        echo [バックアップフォルダ] !DEST_PATH!
        echo [バックアップフォルダ] !DEST_PATH! >> "%LOG_FILE%"
        
        :: robocopy でバックアップ実行
        :: /MIR = ミラーリング（コピー元で削除したファイルはコピー先でも削除）
        :: /DCOPY:DAT = ディレクトリのデータ・属性・タイムスタンプをコピー
        :: /R:3 = 再試行回数 3 回
        :: /W:10 = 再試行間隔 10 秒
        :: /XD = 除外ディレクトリ
        :: /XF = 除外ファイル
        robocopy "!CURRENT_SOURCE_DIR!" "!DEST_PATH!" /MIR /DCOPY:DAT /R:3 /W:10 /XD %EXCLUDE_DIRS% /XF %EXCLUDE_FILES%
        
        set CURRENT_RESULT=!ERRORLEVEL!
        if !CURRENT_RESULT! GTR 7 (
            set OVERALL_RESULT=!CURRENT_RESULT!
            echo [エラー] !CURRENT_SOURCE_DIR! でエラーが発生しました。エラーコード: !CURRENT_RESULT!
        ) else (
            echo [成功] !CURRENT_SOURCE_DIR!
        )
        echo.
    ) else (
        echo [警告] ソースディレクトリが存在しません: !CURRENT_SOURCE_DIR!
        echo [警告] ソースディレクトリが存在しません: !CURRENT_SOURCE_DIR! >> "%LOG_FILE%"
    )
)

set BACKUP_RESULT=%OVERALL_RESULT%

echo バックアップ処理が終了しました。
echo ログファイル: %LOG_FILE%
echo.
pause
