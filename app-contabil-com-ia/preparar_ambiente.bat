@echo off
setlocal
cd /d "%~dp0"
set "PATH=%USERPROFILE%\.local\bin;%USERPROFILE%\.cargo\bin;%PATH%"

where uv >nul 2>&1
if errorlevel 1 (
  echo uv nao foi encontrado.
  echo.
  echo Instale no PowerShell com:
  echo   irm https://astral.sh/uv/install.ps1 ^| iex
  echo.
  echo Depois feche e abra este arquivo de novo.
  pause
  exit /b 1
)

echo Baixando Python 3.12 com uv, se ainda nao estiver disponivel...
uv python install 3.12
if errorlevel 1 goto erro

echo Criando o ambiente .venv...
uv venv --python 3.12 .venv
if errorlevel 1 goto erro

echo Instalando dependencias...
uv pip install --python ".venv\Scripts\python.exe" -r requirements.txt
if errorlevel 1 goto erro

echo Ambiente preparado com uv. Execute iniciar.bat.
pause
exit /b 0
:erro
echo A preparacao falhou. Verifique a mensagem acima.
pause
exit /b 1
