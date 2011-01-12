@echo off
IF "%1%"=="64" ECHO "BUILDING 64bit solution" 
IF NOT "%1%"=="64" ECHO "BUILDING 32bit solution"

SET OS_MODE=
IF "%1%"=="64" SET OS_MODE= Win64
  
SET PROGRAMFILES_DIR_X86=%programfiles(x86)%
if NOT EXIST "%PROGRAMFILES_DIR_X86%" SET PROGRAMFILES_DIR_X86=%programfiles%
SET PROGRAMFILES_DIR=%programfiles%

REM Find CMake  
SET CMAKE="cmake.exe"
IF EXIST "%PROGRAMFILES_DIR_X86%\CMake 2.8\bin\cmake.exe" SET CMAKE="%PROGRAMFILES_DIR_X86%\CMake 2.8\bin\cmake.exe"

IF EXIST "CMakeCache.txt" del CMakeCache.txt

REM Find Visual Studio or Msbuild
SET VS2005="%PROGRAMFILES_DIR_X86%\Microsoft Visual Studio 8\Common7\IDE\devenv.exe"
SET VS2008="%PROGRAMFILES_DIR_X86%\Microsoft Visual Studio 9.0\Common7\IDE\devenv.exe"
REM SET VS2010="%PROGRAMFILES_DIR_X86%\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe"
SET MSBUILD35="%windir%\Microsoft.NET\Framework\v3.5\MSBuild.exe"

IF EXIST %MSBUILD35% SET DEVENV=%MSBUILD35%
IF EXIST %VS2005% SET DEVENV=%VS2005% 
IF EXIST %VS2008% SET DEVENV=%VS2008%
REM IF EXIST %VS2010% SET DEVENV=%VS2010%

IF %DEVENV%==%MSBUILD35% SET BUILD_TYPE=/property:Configuration=Release
IF %DEVENV%==%VS2005% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2008% SET BUILD_TYPE=/Build Release
REM IF %DEVENV%==%VS2010% SET BUILD_TYPE=/Build Release

IF %DEVENV%==%MSBUILD35% SET CMAKE_CONF="Visual Studio 8 2005%OS_MODE%"
IF %DEVENV%==%VS2005% SET CMAKE_CONF="Visual Studio 8 2005%OS_MODE%"
IF %DEVENV%==%VS2008% SET CMAKE_CONF="Visual Studio 9 2008%OS_MODE%"
REM IF %DEVENV%==%VS2010% SET CMAKE_CONF="Visual Studio 10%OS_MODE%"

SET CMAKE_CONF_FLAGS= -G %CMAKE_CONF% -DBUILD_DOXYGEN_DOCS:BOOL=FALSE -DBUILD_TESTS:BOOL=FALSE -DBUILD_NEW_PYTHON_SUPPORT:BOOL=FALSE -DOPENCV_WHOLE_PROGRAM_OPTIMIZATION:BOOL=TRUE -DEMGU_ENABLE_SSE:BOOL=TRUE 

IF "%4%"=="doc" ^
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DEMGU_CV_DOCUMENT_BUILD:BOOL=TRUE

IF NOT "%2%"=="gpu" GOTO END_OF_GPU

:WITH_GPU
REM Find cuda
SET CUDA_SDK_DIR=%PROGRAMFILES_DIR_X86%\NVIDIA GPU Computing Toolkit\CUDA\v3.2
IF "%OS_MODE%"==" Win64" SET CUDA_SDK_DIR=%PROGRAMFILES_DIR%\NVIDIA GPU Computing Toolkit\CUDA\v3.2
SET NPP_SDK_DIR=%CUDA_SDK_DIR%\npp_3.2.16_win_32\SDK
IF "%OS_MODE%"==" Win64" SET NPP_SDK_DIR=%CUDA_SDK_DIR%\npp_3.2.16_win_64\SDK
echo %NPP_SDK_DIR%

IF EXIST "%NPP_SDK_DIR%" SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DWITH_CUDA:BOOL=TRUE -DCUDA_VERBOSE_BUILD:BOOL=TRUE -DCUDA_TOOLKIT_ROOT_DIR="%CUDA_SDK_DIR%" -DCUDA_SDK_ROOT_DIR="%CUDA_SDK_DIR%" -DCUDA_NPP_LIBRARY_ROOT_DIR="%NPP_SDK_DIR%" 
:END_OF_GPU

IF "%3%"=="intel" GOTO INTEL_COMPILER
IF NOT "%3%"=="intel" GOTO VISUAL_STUDIO

:INTEL_COMPILER
REM Find Intel Compiler 
SET INTEL_DIR=%PROGRAMFILES_DIR_X86%\Intel\ComposerXE-2011\bin
SET INTEL_ENV=%INTEL_DIR%\iclvars.bat
SET INTEL_ICL=%INTEL_DIR%\ia32\icl.exe
IF "%OS_MODE%"==" Win64" SET INTEL_ICL=%INTEL_DIR%\intel64\icl.exe
SET INTEL_TBB=%INTEL_DIR%\..\tbb\include
SET ICPROJCONVERT=%PROGRAMFILES_DIR_X86%\Common Files\Intel\shared files\ia32\Bin\ICProjConvert120.exe

REM initiate the compiler enviroment
@echo on
REM IF "%OS_MODE%"=="" CALL "%INTEL_ENV%" ia32
REM IF "%OS_MODE%"==" WIN64" CALL "%INTEL_ENV%" intel64

REM SET INTEL_ICL_CMAKE=%INTEL_ICL:\=/%
SET INTEL_TBB_CMAKE=%INTEL_TBB:\=/%

REM SET INTEL_ICL_COMPILER_FLAGS="/STACK:10000000 /INCREMENTAL:NO /machine:X86"
SET INTEL_ICL_LINKER_FLAGS="/QaxSSE4.1 /Qparallel /Quse-intel-optimized-headers /EHa"

SET CMAKE_CONF_FLAGS=-DUSE_O3:BOOL=TRUE ^
-DCMAKE_CXX_FLAGS=%INTEL_ICL_LINKER_FLAGS% ^
-DCMAKE_C_FLAGS=%INTEL_ICL_LINKER_FLAGS% ^
-DWITH_TBB:BOOL=TRUE ^
-DTBB_INCLUDE_DIR="%INTEL_TBB_CMAKE%" ^
-DUSE_IPP:BOOL=TRUE ^
-DCV_ICC:BOOL=TRUE ^
%CMAKE_CONF_FLAGS%

REM create visual studio project
%CMAKE% %CMAKE_CONF_FLAGS%

REM convert the project to intel 
"%ICPROJCONVERT%" emgucv.sln /IC

GOTO BUILD

:VISUAL_STUDIO
@echo on
%CMAKE% %CMAKE_CONF_FLAGS% -DUSE_IPP:BOOL=FALSE .  

:BUILD

SET BUILD_PROJECT=
IF "%5%"=="package" SET BUILD_PROJECT= /project PACKAGE 
%DEVENV% %BUILD_TYPE% emgucv.sln