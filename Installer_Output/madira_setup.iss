; Script generated for Madera Kitchen Fabrication
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Madera Kitchen Fabrication"
#define MyAppVersion "1.0"
#define MyAppPublisher "Madera Kitchen"
#define MyAppExeName "madira.exe"

; =====================================================================
; PATH CONFIGURATION - UPDATED BASED ON YOUR LS OUTPUT
; =====================================================================
#define SourceFrontend "F:\\madira\\frontend\\madira\\build\\windows\\x64\\runner\\Release"
#define SourceBackend  "F:\\madira\\backend\\madira"
; Icon file location
#define SourceIcon     "F:\\madira\\frontend\\madira\\assets\\images\\logo.ico"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-1234567890AB}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://www.maderakitchen.com
AppSupportURL=https://www.maderakitchen.com/support
AppUpdatesURL=https://www.maderakitchen.com/updates
; Installs to C:\Program Files\Madera Kitchen Fabrication
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
; Modern UI Configuration
WizardStyle=modern
WizardResizable=yes
WizardSizePercent=120,100
DisableWelcomePage=no
OutputDir=F:\madira\Installer_Output
OutputBaseFilename=MaderaKitchen_Setup_v1.0
SetupIconFile={#SourceIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
; Custom images for modern look (optional - create these for even better UI)
;WizardImageFile=compiler:WizModernImage-IS.bmp
;WizardSmallImageFile=compiler:WizModernSmallImage-IS.bmp
Compression=lzma
SolidCompression=yes
; Admin privileges required to write to Program Files
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64
; Visual enhancements
ShowLanguageDialog=auto
DisableProgramGroupPage=no
DisableReadyPage=no
DisableFinishedPage=no
; License and info files (create these for better UX)
;LicenseFile=LICENSE.txt
;InfoBeforeFile=README.txt
;InfoAfterFile=INSTALLATION_GUIDE.md

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "master"; Description: "Master Installation (Full System - App + Backend)"
Name: "slave"; Description: "Slave Installation (Client Only - App)"

[Components]
Name: "app"; Description: "Madera Kitchen Application"; Types: master slave; Flags: fixed
Name: "backend"; Description: "Backend System (Django + Database)"; Types: master

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; --- FRONTEND FILES (Always installed) ---
Source: "{#SourceFrontend}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion; Components: app
Source: "{#SourceFrontend}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: app

; --- BACKEND FILES (Only if Master is selected) ---
; We install the backend into a subfolder named 'backend'
; This includes: ALL Django files - manage.py, Python files, templates, static files, CSS, JS, images, migrations, etc.
Source: "{#SourceBackend}\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "db.sqlite3,*.db,*.sqlite,*.sqlite3-journal,.gitignore,master.dart,slave.dart,__pycache__,*.pyc,*.pyo,venv,env,.venv"; Components: backend
; Explicitly copy manage.py to ensure it's included
Source: "{#SourceBackend}\manage.py"; DestDir: "{app}\backend"; Flags: ignoreversion; Components: backend
; Database file (OPTIONAL) - Only copied if it exists in source, NEVER uninstalled
Source: "{#SourceBackend}\db.sqlite3"; DestDir: "{app}\backend"; Flags: ignoreversion uninsneveruninstall onlyifdoesntexist skipifsourcedoesntexist; Components: backend
; note: Database will be created by migrations if it doesn't exist. Once created, it's protected from uninstall and manual deletion
; Note: All Django components are included - manage.py, static/, media/, templates/, apps/, migrations/, settings.py, urls.py, wsgi.py, CSS, JavaScript, images
; Files are VISIBLE (not hidden) for easier troubleshooting and maintenance

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Dirs]
; CRITICAL: We grant 'modify' permissions because db.sqlite3 needs to be written to.
; If we make this read-only, the app will crash when saving data.
Name: "{app}\backend"; Permissions: users-modify; Components: backend
; Create logs directory with write permissions for Flutter app logs
Name: "{app}\logs"; Permissions: users-modify

[Run]
; --- PYTHON SETUP (Master Mode Only) ---

; 1. Install requirements using the specific req.txt file
Filename: "cmd.exe"; Parameters: "/c ""python -m pip install -r req.txt"""; WorkingDir: "{app}\backend"; Flags: waituntilterminated runhidden; Components: backend; Description: "Installing Python dependencies (req.txt)..."

; 2. Make migrations (Generate migration files for any model changes)
Filename: "cmd.exe"; Parameters: "/c ""python manage.py makemigrations"""; WorkingDir: "{app}\backend"; Flags: waituntilterminated runhidden; Components: backend; Description: "Generating database migrations..."

; 3. Run Migrations (Creates db.sqlite3 if doesn't exist, updates if it does)
Filename: "cmd.exe"; Parameters: "/c ""python manage.py migrate"""; WorkingDir: "{app}\backend"; Flags: waituntilterminated runhidden; Components: backend; Description: "Applying database migrations..."

; 3a. Create static directory if it doesn't exist
Filename: "cmd.exe"; Parameters: "/c ""if not exist static mkdir static"""; WorkingDir: "{app}\backend"; Flags: runhidden; Components: backend

; 3b. Collect static files (CSS, JS, images for Django admin and apps) - FORCE collect all
Filename: "cmd.exe"; Parameters: "/c ""python manage.py collectstatic --noinput --clear --verbosity 0"""; WorkingDir: "{app}\backend"; Flags: waituntilterminated runhidden; Components: backend; Description: "Collecting static files (including admin CSS)..."

; 3c. Verify static files were collected successfully
Filename: "cmd.exe"; Parameters: "/c ""if exist static\admin\css\base.css (exit 0) else (exit 1)"""; WorkingDir: "{app}\backend"; Flags: runhidden; Components: backend

; 3d. Set proper permissions on static folder
Filename: "icacls.exe"; Parameters: """{app}\backend\static"" /grant Users:(OI)(CI)F /T 2>nul"; Flags: runhidden; Components: backend

; 4. Create Django superuser 'xtradev' with password '123'
Filename: "cmd.exe"; Parameters: "/c ""echo Creating admin user... && python -c ""import os; os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project.settings'); import django; django.setup(); from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='xtradev').exists() or User.objects.create_superuser('xtradev', 'admin@madira.local', '123')"""""; WorkingDir: "{app}\backend"; Flags: waituntilterminated runhidden; Components: backend

; 5. Ensure database is writable - remove any read-only attributes
Filename: "cmd.exe"; Parameters: "/c ""if exist ""{app}\backend\db.sqlite3"" attrib -R -S -H ""{app}\backend\db.sqlite3"" 2>nul"""; Flags: runhidden; Components: backend

; 6. Grant full write permissions to backend folder and static files
Filename: "icacls.exe"; Parameters: """{app}\backend"" /grant Users:(OI)(CI)F /T"; Flags: runhidden; Components: backend; Description: "Setting folder permissions..."
Filename: "cmd.exe"; Parameters: "/c ""if exist ""{app}\backend\static"" icacls ""{app}\backend\static"" /grant Users:(OI)(CI)F /T 2>nul"""; Flags: runhidden; Components: backend

; 6a. Deny delete permission on backend folder to prevent manual deletion
Filename: "icacls.exe"; Parameters: """{app}\backend"" /deny Users:(DE)"; Flags: runhidden; Components: backend; Description: "Protecting backend folder..."

; 7. Create backup of database
Filename: "cmd.exe"; Parameters: "/c ""if exist ""{app}\backend\db.sqlite3"" copy /Y ""{app}\backend\db.sqlite3"" ""{app}\backend\db_backup.sqlite3"" 2>nul"""; Flags: runhidden; Components: backend

; 8. Create backend configuration file for Flutter app
Filename: "cmd.exe"; Parameters: "/c ""(echo {{""backend_path"": ""{app}\backend""}}) > ""{app}\backend_config.json"""; Flags: runhidden; Components: backend

; 9. Create backend path marker file
Filename: "cmd.exe"; Parameters: "/c ""echo {app}\backend > ""{app}\backend_path.txt"""; Flags: runhidden; Components: backend

; 10. Set environment variable for backend path
Filename: "cmd.exe"; Parameters: "/c ""setx MADIRA_BACKEND_PATH ""{app}\backend"" /M"""; Flags: runhidden; Components: backend

; 11. Grant write permissions to app root folder for log files
Filename: "icacls.exe"; Parameters: """{app}"" /grant Users:(OI)(CI)M"; Flags: runhidden; Description: "Setting log permissions..."

; 12. Grant write permissions specifically to logs folder
Filename: "icacls.exe"; Parameters: """{app}\logs"" /grant Users:(OI)(CI)F /T"; Flags: runhidden

; 13. Create empty log file with proper permissions
Filename: "cmd.exe"; Parameters: "/c ""type nul > ""{app}\madira_app_log.txt"" && icacls ""{app}\madira_app_log.txt"" /grant Users:F"""; Flags: runhidden

; 14. Launch App
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Remove delete protection from backend folder during uninstall
Filename: "icacls.exe"; Parameters: """{app}\backend"" /remove:d Users"; Flags: runhidden

[Code]
var
  InstallTypePage: TInputOptionWizardPage;

function IsPythonInstalled: Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('cmd.exe', '/c python --version 2>&1 | findstr /R "Python 3\."', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

procedure InitializeWizard();
begin
  InstallTypePage := CreateInputOptionPage(wpLicense, 'Installation Type', 'Choose how you want to install Madera Kitchen Fabrication', 'Select Master for server with backend and database, or Slave for client-only installation.', True, False);
  InstallTypePage.Add('Master Installation (Server) - Complete system with backend and database');
  InstallTypePage.Add('Slave Installation (Client) - Application only, connects to Master server');
  InstallTypePage.Values[0] := True;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  I: Integer;
begin
  if CurPageID = wpSelectComponents then
  begin
    for I := 0 to WizardForm.ComponentsList.Items.Count - 1 do
    begin
      if Pos('Backend', WizardForm.ComponentsList.ItemCaption[I]) > 0 then
      begin
        if InstallTypePage.Values[1] then
        begin
          WizardForm.ComponentsList.Checked[I] := False;
          WizardForm.ComponentsList.ItemEnabled[I] := False;
        end
        else
        begin
          WizardForm.ComponentsList.ItemEnabled[I] := True;
        end;
      end;
    end;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  
  if CurPageID = InstallTypePage.ID then
  begin
    if InstallTypePage.Values[0] then
      WizardForm.TypesCombo.ItemIndex := 0
    else
      WizardForm.TypesCombo.ItemIndex := 1;
  end;
  
  if (CurPageID = wpSelectComponents) and WizardIsComponentSelected('backend') then
  begin
    if not IsPythonInstalled then
    begin
      MsgBox('CRITICAL WARNING:' + #13#10#13#10 + 'Python 3.x was not found on this computer.' + #13#10 + 'The Master/Backend installation requires Python 3.8+ installed and added to PATH.' + #13#10 + 'Please install Python 3.x before continuing, or the backend will fail to start.' + #13#10#13#10 + 'Download from: https://www.python.org/downloads/', mbCriticalError, MB_OK);
    end;
  end;
end;

function InitializeUninstall(): Boolean;
var
  Response: Integer;
begin
  Response := MsgBox('Uninstalling Madera Kitchen Fabrication' + #13#10#13#10 + 'NOTE: Your database (db.sqlite3) will be PRESERVED and not deleted.' + #13#10 + 'All other application files will be removed.' + #13#10#13#10 + 'If you want to completely remove all data, manually delete:' + #13#10 + 'C:\Program Files\Madera Kitchen Fabrication\backend\db.sqlite3' + #13#10#13#10 + 'Do you want to continue with uninstallation?', mbInformation, MB_YESNO);
  Result := (Response = IDYES);
end;
