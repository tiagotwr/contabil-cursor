@echo off
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo O ambiente ainda nao foi preparado.
  echo De dois cliques em preparar_ambiente.bat — ele usa o uv e nao precisa do Python no sistema.
  pause
  exit /b 1
)
".venv\Scripts\python.exe" "%~dp0scripts\local.py" --start
if errorlevel 1 (
  pause
  exit /b 1
)
for /f "usebackq delims=" %%U in (`powershell -NoProfile -Command "$s=Get-Content -Raw '%~dp0.runtime\estado.json' | ConvertFrom-Json; if ($s.url) {$s.url}"`) do start "App Contábil" "%%U"
