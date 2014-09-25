with Ada.Text_IO;
with Ada.Directories;
with Ada.Direct_IO;
with Ada.Strings.Fixed;
with Ada.Calendar;

with AWS.Server;
with AWS.Config;
with AWS.Net;
with PolyORB.Parameters;

with webserver;
with remote_types;
with the_name_server;

use Ada;
use Ada.Text_IO;
use Ada.Strings.Fixed;
use Ada.Calendar;

use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;

use remote_types;
use webserver;
use the_name_server;

procedure nameserver_starter is
  WebS : Access_WebServer_Remote_Interface;
  -- I : Natural;
  -- Last : Integer;
  -- Par : String (1 .. 255) := (others => '');
  M : String(1 .. 255);
  Data_Dir : String := "../data/";
  Data_File_Prefix : String := "QUARTIERE";
  Num_Part : Integer := 3;
  L : Natural;
  IOR : String := PolyORB.Parameters.Get_Conf ("dsa", "name_service", "");
  IOR_File : File_Type;
  States_Filename : String := "states.json";
  States_File : Ada.Text_IO.File_Type;
  Ch : Character;
  Available : Boolean;
begin
  Put_Line("Name server is up and located at:");
  --Ada.Text_IO.Put_Line (PolyORB.Parameters.Get_Conf ("dsa", "name_service", ""));
  Put_Line(IOR);
  Create(File => IOR_File, Mode => Out_File, Name => "ns.txt");
  Put_Line(IOR_File, IOR);
  Close(IOR_File);

  WebS := the_name_server.get_webServer;
  Put_Line("Server reference retrieved");

  for I in Integer range 1 .. 3
  loop
    declare
      Partition_Number : constant String := Trim(Integer'Image(I), Ada.Strings.Left);
      File_Name : constant String := Data_Dir & Data_File_Prefix & Partition_Number & ".json";
      File_Size : Natural := Natural(Ada.Directories.Size(File_Name));
 
      subtype File_String    is String (1 .. File_Size);
      package File_String_IO is new Ada.Direct_IO (File_String);
 
      File     : File_String_IO.File_Type;
      Contents : File_String;
    begin 
      File_String_IO.Open(File, Mode => File_String_IO.In_File, Name => File_Name);
      File_String_IO.Read(File, Item => Contents);
      File_String_IO.Close(File);
      Put_Line("Registering quartiere " & Integer'Image(I));
      WebS.registra_mappa_quartiere(Contents, I);
    end;
  end loop;

 
  Put_Line("Press a key to start sending...");
  Get_Immediate (Ch);
  Ch := 'y';
  -- loop
  --   Get_Line (M, L);
  --   WebS.invia_aggiornamento("prova",1);
  --   WebS.invia_aggiornamento(M (M'First .. L), 1);
  --   WebS.invia_aggiornamento("prova",2);
  --   WebS.invia_aggiornamento(M (M'First .. L), 2);
  --   WebS.invia_aggiornamento("prova",3);
  --   WebS.invia_aggiornamento(M (M'First .. L), 3);
  -- end loop;

  Open (File => States_File,
                     Mode => In_File,
                     Name => States_Filename);
  while Ch /= 'n' loop
    Reset(States_File);
    while not End_Of_File (States_File) loop
      declare
         Line : String := Get_Line (States_File);
      begin
         WebS.invia_aggiornamento(Line(Line'First .. Line'Last), 2);
         delay until (Clock + 0.3);
      end;
    end loop;
    Put("Do you want to start again? [y|n] ");
    Get_Immediate(Ch);
    Put_Line("");
  end loop;
  Close (States_File);
end nameserver_starter;