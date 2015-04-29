with remote_types;
with Ada.Text_IO;

with AWS.Config.Set;
with AWS.Default;
with AWS.Net.Log;
with AWS.Net.WebSocket.Registry.Control;
with AWS.Server;
with AWS.Status;
with AWS.Templates;
with AWS.Services.Page_Server;
with AWS.Response;
with AWS.Dispatchers;
with AWS.Dispatchers.Callback;
with Page_CB;
with Websock_CB;
with Home_Page;
with JS_Page_Compiler;

use Page_CB;
use Websock_CB;
use Home_Page;
use JS_Page_Compiler;

use Ada;
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;

use remote_types;

package body webserver_remote_proxy is
   
   Admin_Dir : String := "hg";
   
   protected body WebServer_Remote_Proxy_Type is

      procedure registra_webserver(webS : Access_WebServer_Wrapper) is
      begin
         WS := webS;
      end;
   
      procedure registra_mappa_quartiere(json: String;  id : Natural) is
         MyStatic : Static_page;
         TmpID : String := Natural'Image(id);
         StringID : String := TmpID(TmpID'First+1 .. TmpID'Last);
      begin
         Text_IO.Put_Line(json);
         MyStatic.Init(id, json);
         Text_IO.Put_Line("Activating /quartiere" & StringID);
         Services.Dispatchers.URI.Register(Root, "/quartiere" & StringID, MyStatic);
         Page_Handler_Registry(id) := MyStatic;
         Server.Set(WS, Root);
      end registra_mappa_quartiere;

      procedure invia_aggiornamento(data: String; quartiere: Natural) is
      begin
         Net.WebSocket.Registry.Send (Rcp, data);
      end invia_aggiornamento;

      procedure Init is
         MyHome_Page : Home_Page_Handler;
         JS_Compiler : JS_Page_Compiler_Handler;
      begin
         AWS.Config.Set.Reuse_Address(WsConfig, True);
         AWS.Config.Set.WWW_Root(WsConfig,"/home/marcobaesso/Scrivania/TrafficoViarioSCD/web_view/www_data");
         AWS.Config.Set.Admin_URI(WsConfig,"/home/marcobaesso/Scrivania/TrafficoViarioSCD/web_view/admin_aws");
         AWS.Config.Set.Admin_Password(WsConfig, "f3378e86bbcb838a242ab29627425b93");
         AWS.Config.Set.Status_Page(WsConfig, Admin_Dir & "/home/marcobaesso/Scrivania/TrafficoViarioSCD/web_view/aws_status.thtml");
         AWS.Config.Set.Up_Image(WsConfig,Admin_Dir & "/home/marcobaesso/Scrivania/TrafficoViarioSCD/web_view/aws_up.png");
         AWS.Config.Set.Down_Image(WsConfig,Admin_Dir & "/home/marcobaesso/Scrivania/TrafficoViarioSCD/web_view/aws_down.png");
         AWS.Config.Set.Logo_Image(WsConfig,Admin_Dir & "/home/marcobaesso/Scrivania/TrafficoViarioSCD/web_view/aws_logo.png");

         Text_IO.Put_Line
           ("Call me on port" & Positive'Image (AWS.Default.Server_Port));

         Services.Dispatchers.URI.Register_Default_Callback(Root, AWS.Dispatchers.Callback.Create(AWS.Services.Page_Server.Callback'Access));
         Services.Dispatchers.URI.Register(Root, "/", MyHome_Page);
         Services.Dispatchers.URI.Register(Root, "/we_js/", JS_Compiler, True);
         Server.Start
           (WS, Root, WsConfig);

         Rcp := Net.WebSocket.Registry.Create (URI => "/websock");

         Net.WebSocket.Registry.Control.Start;
         Net.WebSocket.Registry.Register ("/websock", Websocket_Factory'Access);
      end Init;

      procedure Clean is
      begin
         for I in Page_Handler_Registry'Range loop
            Page_Handler_Registry(I).Clean;
         end loop;
         Text_IO.Put_Line("Cleaning the temp files");
      end Clean;

      procedure Shutdown is
      begin 
         Server.Shutdown(WS);
         Clean;
      end Shutdown; 

   end WebServer_Remote_Proxy_Type;

end webserver_remote_proxy;
