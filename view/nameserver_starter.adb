with Ada.Text_IO;
with webserver;

with AWS.Server;
with AWS.Config;
with AWS.Net;
with remote_types;
with the_name_server;
with PolyORB.Parameters;

use Ada;
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;
use Ada.Text_IO;

use remote_types;
use webserver;
use the_name_server;

procedure nameserver_starter is
  WebS : Access_WebServer_Wrapper_Interface;
  -- I : Natural;
  -- Last : Integer;
  -- Par : String (1 .. 255) := (others => '');
  M : String(1 .. 255);
  L : Natural;
  IOR : String := PolyORB.Parameters.Get_Conf ("dsa", "name_service", "");
  IOR_File : File_Type;
begin
  Put_Line("Name server is up and located at:");
  --Ada.Text_IO.Put_Line (PolyORB.Parameters.Get_Conf ("dsa", "name_service", ""));
  Put_Line(IOR);
  Create(File => IOR_File, Mode => Out_File, Name => "ns.txt");
  Put_Line(IOR_File, IOR);
  Close(IOR_File);

  WebS := the_name_server.get_webServer;
  Put_Line("Server reference retrieved");
  WebS.registra_mappa_quartiere("Good",1);
  Put_Line("Write a string to send:");
  Get_Line (M, L);
  WebS.invia_aggiornamento(M (M'First .. L), 1);
end nameserver_starter;