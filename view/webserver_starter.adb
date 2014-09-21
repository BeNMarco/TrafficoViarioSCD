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
use WebServer;

procedure webserver_starter is
  WebS : Access_Remote_Proxy_Type := new Remote_Proxy_Type(the_name_server.get_num_quartieri);
  WebSRef : Access_WebServer_Remote_Interface := Access_WebServer_Remote_Interface(WebS);
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


  Text_IO.Put_Line ("You can now press Q to exit.");

  AWS.Server.Wait (Server.Q_Key_Pressed);

   --  Now shuthdown the servers (HTTP and WebClient)

  WebS.Shutdown;
end webserver_starter;