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

package body webserver is
   
   Admin_Dir : String := "admin_data";
   
   protected body WebServer_Wrapper_Type is
   
      procedure registra_mappa_quartiere(json: String;  id : Natural) is
         MyStatic : Static_page;
         TmpID : String := Natural'Image(id);
         StringID : String := TmpID(TmpID'First+1 .. TmpID'Last);
      begin
         Text_IO.Put_Line(json);
         MyStatic.Set_Id(id);
         MyStatic.Set_Data(json);
         Text_IO.Put_Line("Activating /quartiere" & StringID);
         Services.Dispatchers.URI.Register(Root, "/quartiere" & StringID, MyStatic);
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
         AWS.Config.Set.WWW_Root(WsConfig,"www_data");
         AWS.Config.Set.Admin_URI(WsConfig,"/admin_aws");
         AWS.Config.Set.Admin_Password(WsConfig, "f3378e86bbcb838a242ab29627425b93");
         AWS.Config.Set.Status_Page(WsConfig, Admin_Dir & "/aws_status.thtml");
         AWS.Config.Set.Up_Image(WsConfig,Admin_Dir & "/aws_up.png");
         AWS.Config.Set.Down_Image(WsConfig,Admin_Dir & "/aws_down.png");
         AWS.Config.Set.Logo_Image(WsConfig,Admin_Dir & "/aws_logo.png");

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

      procedure Shutdown is
      begin 
         Server.Shutdown(WS);
      end Shutdown; 

   end WebServer_Wrapper_Type;

end webserver;
