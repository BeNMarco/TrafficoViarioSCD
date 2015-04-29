with remote_types;
with Ada.Text_IO;
with webserver;
with the_name_server;
with System.RPC;

with AWS.Server;
with AWS.Config;
with AWS.Net;
with remote_types;
with the_name_server;

use the_name_server;
use Ada;
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;

use remote_types;
use WebServer;

procedure webserver_starter is
   WebS : Access_Remote_Proxy_Type:= new Remote_Proxy_Type(get_num_quartieri);
   WebSRef : Access_WebServer_Remote_Interface:= Access_WebServer_Remote_Interface(WebS);
   all_ok: Boolean:= True;
   exit_system: Boolean:= False;
begin
   begin
      WebS.Init;
      the_name_server.registra_webserver(WebSRef,all_ok);
      if all_ok=False then
         -- server già registrato
         return;
      end if;
   exception
      when others =>
         WebS.Shutdown;
         return;
   end;

   Ada.Text_IO.Put_Line("Starting the webserver");
   Ada.Text_IO.Put_Line("Server is up, waiting for remote partitions..");

   loop
      delay 1.0;
      begin
         if is_web_server_registered then
            null;
         end if;
      exception
         when others =>
            exit_system:= True;
      end;
      exit when exit_system or not WebS.is_alive;
   end loop;
   WebS.Shutdown;
   Ada.Text_IO.Put_Line("WebServer is gone away");
   the_name_server.set_web_server_closure;
end webserver_starter;
