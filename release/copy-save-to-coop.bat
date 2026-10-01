@echo off
rem Executor Rework: copies your Nightreign save (NR0000.sl2) to the Seamless Co-op save
rem (NR0000.co2) in the same folder, so co-op starts with your progress. An existing co-op
rem save is left alone. Run it with the game closed.
setlocal
set found=0
for /d %%D in ("%APPDATA%\Nightreign\*") do (
    if exist "%%D\NR0000.sl2" (
        set found=1
        if exist "%%D\NR0000.co2" (
            echo Co-op save already exists, left it alone: %%D\NR0000.co2
        ) else (
            copy "%%D\NR0000.sl2" "%%D\NR0000.co2" >nul && echo Created %%D\NR0000.co2
        )
    )
)
if "%found%"=="0" echo No Nightreign save found in %APPDATA%\Nightreign
pause
