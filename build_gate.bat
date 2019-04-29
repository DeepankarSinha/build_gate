@echo off
Setlocal enabledelayedexpansion

echo _______________________________________________________________
echo    ____                                  __                   
echo     /   )           ,   /       /       /    )                 
echo ---/__ /---------------/----__-/-------/---------__--_/_----__-
echo   /    )   /   /  /   /   /   /       /  --,   /   ) /    /___)
echo _/____/___(___(__/___/___(___/_______(____/___(___(_(_ __(___ _
echo  V: 0.0.1
echo  For this to work the head commit must be a merge commit!
echo.

::Configuration
set PRE_EXECUTE=echo HELLO
set POST_EXECUTE=echo HELLO END

::Be careful to increment the array index correctly
set WHEN_I_FIND[0]=.ts
set I_EXECUTE[0]=echo Found ts
set WHEN_I_FIND[1]=.cs
set I_EXECUTE[1]=echo Found cs
::End Configuration


GOTO :Main

:SetLastCommitHash
for /f %%i in ('git rev-parse HEAD') do set "%~1=%%i"
Exit /b 0

:SetMergeCommitRange
for /f "delims=" %%i in ('git show --no-patch --format^="%%P" HEAD') do set hashes=%%i
set %~1=%hashes:~0,40%
set %~2=%hashes:~41,40%
Exit /b 0

:SetFilesModified
for /f %%i in ('git diff --name-only %~1 %~2') do call set "f=%%f%%,%%i"
set %~3=%f:~1%
Exit /b 0

:Search
echo.%~1 | findstr /IC:"%~2">nul && (
    set %~3=TRUE
) || ( 
    set %~3=FALSE 
)
Exit /b 0

:Run
echo Executing: %~1
%~1
Exit /b 0

GOTO :End

:Main 

::Run pre execute if defined
if defined PRE_EXECUTE (
    echo Running pre execute command
    Call :Run "%PRE_EXECUTE%"
)

Call :SetLastCommitHash commitHash
::echo Hash: %commitHash%

Call :SetMergeCommitRange hash1 hash2
::echo Hash1: %hash1%
::echo Hash2: %hash2%
if not defined hash2 ( GOTO :NotAMergeCommitError )
echo Merge commit found^^!

Call :SetFilesModified %hash2% %hash1% files
echo Files: %files%

set /a count=0
set /a found=0

:FindLoop
if defined WHEN_I_FIND[%count%] (
    Call set a=%%WHEN_I_FIND[%count%]%%

    Call :Search "%files%" "%%a%%" flag
    if !flag!==TRUE ( 
        Call :Run "%%I_EXECUTE[%count%]%%"
        Call set found=found+1
    )

    set /a "count+=1"
    GOTO :FindLoop
)

if %found%==0 (
    echo No files matched the criteria.
)

::Run post execute if defined
if defined POST_EXECUTE (
    echo Running post execute command
    Call :Run "%POST_EXECUTE%"
)

GOTO :End


:NotAMergeCommitError
echo Head commit is not a merge commit.
GOTO :End

:End
endlocal
echo My work is done, bye^!