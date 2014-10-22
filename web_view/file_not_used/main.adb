with Ada.Text_IO;
with webserver;

with AWS.Server;
with AWS.Config;
with AWS.Net;
with remote_types;
with the_name_server;

use Ada;
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;

use remote_types;
use webserver;
use the_name_server;

procedure Main is
  WebS : Access_WebServer_Wrapper_Interface;
  -- I : Natural;
  -- Last : Integer;
  -- Par : String (1 .. 255) := (others => '');
  M : String(1 .. 255);
  L : Natural;
begin
  WebS := the_name_server.get_webServer;
  Ada.Text_IO.Put_Line("Server reference retrieved");
  WebS.registra_mappa_quartiere("Good",1);
  Ada.Text_IO.Put_Line("Write a string to send:");
  Ada.Text_IO.Get_Line (M, L);
  WebS.invia_aggiornamento(M (M'First .. L), 1);
end Main;