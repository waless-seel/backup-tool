@echo off
setlocal enabledelayedexpansion

:: ==============================================
:: Windows Automated Backup Script
:: ==============================================

:: 設定セクション - 必要に応じて編集してください

:: バックアップ対象フォルダ（複数指定可能、スペースで区切る）
set SOURCE_DRIVE=C:
set SOURCE_DIRS=Users\%USERNAME%\Pictures Users\%USERNAME%\Videos Users\%USERNAME%\Music

set BACKUP_DRIVE=D:
set BACKUP_ROOT_DIR=Backup
set BACKUP_BASE_DIR=%BACKUP_DRIVE%\%BACKUP_ROOT_DIR%

:: 除外フォルダ（robocopyの/XDオプション用、スペースで区切る）
set EXCLUDE_DIRS=temp tmp cache node_modules .git __pycache__ OneDrive GoogleDrive GooglePhoto Steam

:: 除外ファイル（robocopyの/XFオプション用、スペースで区切る）
set EXCLUDE_FILES=*.temp *.tmp *.log thumbs.db desktop.ini

:: ログファイル
set LOG_FILE=%BACKUP_BASE_DIR%\backup_log.txt

:: 日時取得（YYYY-MM-DD_HH-MM-SS形式）
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"

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
        
        :: ソースフォルダ名と出力先を結合してバックアップ先に追加
        set "DEST_PATH=!BACKUP_DIR!\!CURRENT_SOURCE!"
        echo [バックアップフォルダ] !DEST_PATH!
        echo [バックアップフォルダ] !DEST_PATH! >> "%LOG_FILE%"
        
        :: robocopyでバックアップ実行
        :: /MIR = ミラーリングを行う
        :: /DCOPY:DAT = タイムスタンプを同一にする
        :: /R:3 = 再試行回数3回
        :: /W:10 = 再試行間隔10秒
        :: /XD = 除外ディレクトリ
        :: /XF = 除外ファイル
        robocopy "!CURRENT_SOURCE_DIR!" "!DEST_PATH!" /MIR /DCOPY:DAT /R:3 /W:10 /XD %EXCLUDE_DIRS% /XF %EXCLUDE_FILES%
        
        set CURRENT_RESULT=!ERRORLEVEL!
        if !CURRENT_RESULT! GTR 7 (
            set OVERALL_RESULT=!CURRENT_RESULT!
            echo [エラー] !CURRENT_SOURCE_DIR! でエラーが発生しました。エラーコード: !CURRENT_RESULT!
        ) else (
            echo [完了] !CURRENT_SOURCE_DIR!
        )
        echo.
    ) else (
        echo [警告] ソースディレクトリが存在しません: !CURRENT_SOURCE_DIR!
        echo [警告] ソースディレクトリが存在しません: !CURRENT_SOURCE_DIR! >> "%LOG_FILE%"
    )
)

set BACKUP_RESULT=%OVERALL_RESULT%

echo バックアップ処理が完了しました。
echo ログファイル: %LOG_FILE%
echo.
pause