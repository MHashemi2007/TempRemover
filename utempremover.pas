unit uTempRemover;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls;

type

  { TfrmTempRemover }

  TfrmTempRemover = class(TForm)
    btnRemoveTemp: TButton;
    pbrTempRemover: TProgressBar;
    procedure btnRemoveTempClick(Sender: TObject);
  private
    NumberOfFilesAndFolders: Integer;
    NumberOfDeleted: Integer;
    procedure CountFilesAndFolders(path: string);
    procedure DeleteFilesAndFolders(path: string);
    procedure DoDelete(path: string);
  public

  end;

var
  frmTempRemover: TfrmTempRemover;

implementation

{$R *.lfm}

{ TfrmTempRemover }

procedure TfrmTempRemover.btnRemoveTempClick(Sender: TObject);
var
  UserTempPath, WinTempPath: string;
begin
  //Get path of temps folder for windows
  UserTempPath := IncludeTrailingBackslash(GetEnvironmentVariable('userprofile')) + 'AppData\Local\Temp';
  WinTempPath := IncludeTrailingBackslash(GetEnvironmentVariable('systemdrive')) + 'Windows\Temp';
  //Reset progress bar
  pbrTempRemover.Position := 0;
  NumberOfFilesAndFolders := 0;
  NumberOfDeleted := 0;
  //Count all files and folders
  CountFilesAndFolders(UserTempPath);
  CountFilesAndFolders(WinTempPath);
  //Prepare progress bar
  pbrTempRemover.Max := NumberOfFilesAndFolders;
  //Delete files and folders inside temp folders
  DoDelete(UserTempPath);
  DoDelete(WinTempPath);
end;

//Count all files and folders
procedure TfrmTempRemover.CountFilesAndFolders(path: string);
var
  Rec: TSearchRec;
begin
  path := IncludeTrailingBackslash(path);
  if FindFirst(path + '*', faAnyFile, Rec) = 0 then
  begin
    try
      repeat
        if (Rec.Name <> '.') and (Rec.Name <> '..') then
        begin
          if (Rec.Attr and faDirectory) = faDirectory then
          begin
            Inc(NumberOfFilesAndFolders);
            CountFilesAndFolders(path + Rec.Name);
          end
          else
          begin
            Inc(NumberOfFilesAndFolders);
          end;
        end;
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec);
    end;
  end;
end;

//Delete entire folder
procedure TfrmTempRemover.DeleteFilesAndFolders(path: string);
var
  Rec: TSearchRec;
begin
  path := IncludeTrailingBackslash(path);
  if FindFirst(path + '*', faAnyFile, Rec) = 0 then
  begin
    try
      repeat
        if (Rec.Name <> '.') and (Rec.Name <> '..') then
        begin
          //Reset attribute for delete
          FileSetAttr(path + Rec.Name, Rec.Attr - faArchive - faReadOnly - faHidden - faSysFile);
          if (Rec.Attr and faDirectory = faDirectory) then
          begin
            DeleteFilesAndFolders(path + Rec.Name);
          end
          else
          begin
            //Delete file
            DeleteFile(path + Rec.Name);
          end;
          //Set progress
          Inc(NumberOfDeleted);
          pbrTempRemover.Position := NumberOfDeleted;
        end;
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec);
    end;
  end;
  //Delete folder
  RemoveDir(path);
  //Set progress
  Inc(NumberOfDeleted);
  pbrTempRemover.Position := NumberOfDeleted;
end;

//Delete files and folders inside another one
procedure TfrmTempRemover.DoDelete(path: string);
var
  Rec: TSearchRec;
begin
  path := IncludeTrailingBackslash(path);
  if FindFirst(path + '*', faAnyFile, Rec) = 0 then
  begin
    try
      repeat
        if (Rec.Name <> '.') and (Rec.Name <> '..') then
        begin
          FileSetAttr(path + Rec.Name, Rec.Attr - faArchive - faReadOnly - faHidden - faSysFile);
          if (Rec.Attr and faDirectory) = faDirectory then
          begin
            DeleteFilesAndFolders(path);
          end
          else
          begin
            DeleteFile(path + Rec.Name);
            Inc(NumberOfDeleted);
            pbrTempRemover.Position := NumberOfDeleted;
          end;
        end;
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec);
    end;
  end;
end;

end.

