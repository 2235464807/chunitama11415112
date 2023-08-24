cd %~dp0

set GAME_ID=SDHD

set PACKAGE_DIR=%~dp0\

set APP_DIR=Y:\%GAME_ID%

set DAEMON_EXE=amdaemon.exe
set DAEMON_CONFIG_COMMON=config_common.json
set DAEMON_CONFIG_SERVER=config_server.json
set DAEMON_CONFIG_CLIENT=config_client.json
set DAEMON_CONFIG_CVT=config_cvt.json
set DAEMON_CONFIG_SP=config_sp.json

set APP_EXE=chusanApp.exe
set UPDATEIOFIRM_EXE=%PACKAGE_DIR%bin\pxUpdateIoFirm.exe
set IOFIRM_FILE=%PACKAGE_DIR%firm\update_15257_6679_91_3EEE.mot

set HWVALUE_EXE=hwvalue.exe

    REM //------------------------------------------------------------------------------
    REM // �A�v���f�[�^�̈�̏���
    REM //------------------------------------------------------------------------------
    if not exist %APP_DIR% (
        rmdir /S /Q "Y:\"
        mkdir "%APP_DIR%"
    )

    REM //------------------------------------------------------------------------------
    REM // �^�C���]�[���̕ύX
    REM //------------------------------------------------------------------------------
    tzutil /s "Tokyo Standard Time"

    REM //------------------------------------------------------------------------------
    REM // �v���Z�X�����I��
    REM //------------------------------------------------------------------------------
    taskkill /im %DAEMON_EXE% > nul 2>&1
    taskkill /f /t /im %APP_EXE% > nul 2>&1

    REM //------------------------------------------------------------------------------
    REM // �폜�҂�
    REM //------------------------------------------------------------------------------
    ping 127.0.0.1 -n 5 > nul 2>&1

    REM //------------------------------------------------------------------------------
    REM // I/O BD �t�@�[���̍X�V
    REM //------------------------------------------------------------------------------
    start /wait %UPDATEIOFIRM_EXE% %IOFIRM_FILE%

pushd bin
    REM //------------------------------------------------------------------------------
    REM // SP/CVT�؂蕪��
    REM //------------------------------------------------------------------------------
    %HWVALUE_EXE% dipsw 7
    if %ERRORLEVEL%==65535 (
    goto END
    )
    set HW_RESULT=%ERRORLEVEL%
    set /A DELIVER_TYPE="(%HW_RESULT%>>0)&1"
    set /A MONITOR_TYPE="(%HW_RESULT%>>1)&1"
    set /A MACHINE_TYPE="(%HW_RESULT%>>2)&1"

    if %MACHINE_TYPE%==0 (
       set MACHINE_CONFIG=%DAEMON_CONFIG_SP%
    ) else (
       set MACHINE_CONFIG=%DAEMON_CONFIG_CVT%
    )

    REM //------------------------------------------------------------------------------
    REM // �v���C�}���[���j�^�[�ݒ�
    REM //------------------------------------------------------------------------------
    if %MONITOR_TYPE%==0 (
       regedit /s port_setting_sp.reg
    ) else (
       regedit /s port_setting.reg
    )

    REM //------------------------------------------------------------------------------
    REM �z�M�T�[�o�E�N���C�A���g���
    REM //------------------------------------------------------------------------------
    if %DELIVER_TYPE%==0 (
       set DELIVER_CONFIG=%DAEMON_CONFIG_CLIENT%
    ) else (
       set DELIVER_CONFIG=%DAEMON_CONFIG_SERVER%
    )

    REM //------------------------------------------------------------------------------
    REM // AMDaemon�N��
    REM //------------------------------------------------------------------------------
    start /min %DAEMON_EXE% -f -c %DAEMON_CONFIG_COMMON% %DELIVER_CONFIG% %MACHINE_CONFIG%

    REM // �A�v���P�[�V�����N��
    start /wait %APP_EXE%

:END

    REM --------------------
    REM app.exe ���� Core::kill �֐����Ă�ł���ꍇ�ł����Ă�
    REM amdaemon.exe �������ɏI������Ƃ͌���Ȃ����߁A�O�̂��ߏ����ҋ@���܂��B
    REM --------------------
    timeout /t 1

    REM //------------------------------------------------------------------------------
    REM // �v���Z�X�����I��
    REM // �A�v���ُ̈�I�����ɂ��amdaemon.exe���I�����Ă��Ȃ��ꍇ������
    REM // ���̏ꍇ�Z�K�u�[�g�֑J�ڂł��Ȃ��̂�kill���Ă���
    REM //------------------------------------------------------------------------------
    taskkill /im %DAEMON_EXE% > nul 2>&1

    for /L %%i in (1, 1, 10) do (
        tasklist | findstr %DAEMON_EXE% > NUL
        if errorlevel 1 goto amdaemon_process_killed
    
        timeout 1 > NUL
    )
:amdaemon_process_killed

popd
rem ��n��
rem ====================
exit /b 0