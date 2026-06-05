@echo off
setlocal enabledelayedexpansion
title Build and Release InvoicesExtract
color 0B

echo ===================================================
echo     INVOICES EXTRACT - AUTO BUILD ^& RELEASE
echo ===================================================

:: ==========================================
:: 0. Lấy thời gian hiện tại cho Commit Message
:: ==========================================
:: Lấy Date (DD/MM/YYYY)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "YY=%datetime:~2,2%" & set "YYYY=%datetime:~0,4%" & set "MM=%datetime:~4,2%" & set "DD=%datetime:~6,2%"
set "HH=%datetime:~8,2%" & set "Min=%datetime:~10,2%"

set COMMIT_MSG=Update: %DD%/%MM%/%YYYY% %HH%:%Min%
echo [*] Thoi gian hien tai: %COMMIT_MSG%

:: ==========================================
:: 1. Dọn dẹp môi trường trước khi Build
:: ==========================================
echo [*] Dang don dep cac file build cu...
if exist "dist" rmdir /s /q "dist"
if exist "build" rmdir /s /q "build"
if exist "InvoicesExtract.spec" del /q "InvoicesExtract.spec"
if exist "InvoicesExtract.zip" del /q "InvoicesExtract.zip"

:: ==========================================
:: 2. Khởi chạy PyInstaller (Build EXE)
:: ==========================================
echo [*] Dang bien dich thanh file .exe va gan Icon...
python -m PyInstaller --noconfirm --onefile --windowed --icon="Icon\InvoicesExtract.ico" --add-data "Icon\InvoicesExtract.ico;Icon" .\InvoicesExtract.py

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PyInstaller gap loi!
    pause
    exit /b
)

:: ==========================================
:: 3. Nén file EXE thành ZIP bằng PowerShell
:: ==========================================
echo [*] Dang nen file InvoicesExtract.zip...
timeout /t 2 /nobreak >nul
powershell -command "Compress-Archive -Path 'dist\InvoicesExtract.exe' -DestinationPath 'InvoicesExtract.zip' -Force"

if not exist "InvoicesExtract.zip" (
    echo [ERROR] Loi khi tao file ZIP!
    pause
    exit /b
)

:: ==========================================
:: 4. Upload file ZIP lên GitHub Releases
:: ==========================================
:: Lấy Tag Name dựa trên ngày giờ (VD: v260605-1001)
set TAG_NAME=v%YY%%MM%%DD%-%HH%%Min%

echo [*] Dang upload %TAG_NAME% len GitHub Release...
gh release create %TAG_NAME% InvoicesExtract.zip --repo cronpostps/InvoicesExtract --title "InvoicesExtract %TAG_NAME%" --notes "Phien ban cap nhat tu dong luc: %DD%/%MM%/%YYYY% %HH%:%Min%"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Khong the upload len GitHub Release, hay kiem tra lai GitHub CLI
) else (
    echo [V] Upload Release thanh cong!
)

:: ==========================================
:: 5. Dọn dẹp các bản Release cũ trên GitHub
:: ==========================================
echo [*] Dang xoa cac ban release cu tren GitHub...
for /f "delims=" %%t in ('gh api repos/cronpostps/InvoicesExtract/releases -q ".[].tag_name"') do (
    if /I NOT "%%t"=="%TAG_NAME%" (
        echo   - Xoa release va tag cu: %%t
        :: Xóa release bỏ qua xác nhận (-y) và xóa luôn Git tag rác (--cleanup-tag)
        gh release delete "%%t" --repo cronpostps/InvoicesExtract -y --cleanup-tag >nul 2>&1
    )
)

:: ==========================================
:: 6. Upload Mã Nguồn Lên GitHub (Nhánh Main)
:: ==========================================
echo [*] Dang dong bo ma nguon len GitHub...
git add .
git commit -m "%COMMIT_MSG%"
git branch -M main
git push origin +main

:: ==========================================
:: 7. Dọn Rác Sau Build (Chỉ giữ dist/InvoicesExtract.exe)
:: ==========================================
echo [*] Dang don dep cac file rac sau khi hoan thanh...
if exist "build" rmdir /s /q "build"
if exist "InvoicesExtract.spec" del /q "InvoicesExtract.spec"
if exist "InvoicesExtract.zip" del /q "InvoicesExtract.zip"

echo ===================================================
echo [V] HOAN THANH TAT CA TIEN TRINH!
echo ===================================================
pause