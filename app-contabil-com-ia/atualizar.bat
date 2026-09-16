@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo O ambiente ainda nao foi preparado.
  echo De dois cliques em preparar_ambiente.bat — ele usa o uv e nao precisa do Python no sistema.
  pause
  exit /b 1
)
".venv\Scripts\python.exe" "%~dp0scripts\atualizar_selecionar.py"
pause
