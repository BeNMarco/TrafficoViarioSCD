with remote_types;
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

procedure webserver_starter is
  WebS : Access_WebServer_Wrapper := new WebServer_Wrapper_Type;
  WebSRef : Access_WebServer_Wrapper_Interface := Access_WebServer_Wrapper_Interface(WebS);
  -- I : Natural;
  -- Last : Integer;
  -- Par : String (1 .. 255) := (others => '');
  -- M : String(1 .. 255);
  -- L : Natural;
begin
  Ada.Text_IO.Put_Line("Starting the webserver");
  WebS.Init;
  -- WebS.registra_mappa_quartiere("Good",1);
  the_name_server.registra_webserver(WebSRef);
  Ada.Text_IO.Put_Line("Server is up, waiting for remote partitions..");
end webserver_starter;