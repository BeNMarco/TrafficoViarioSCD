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

package body WebServer is
   
   Admin_Dir : String := "admin_data";
   WWW_Root : String := "www_data";
   
   --protected body WebServer_Wrapper_Type is
   overriding procedure Finalize(This : in out WebServer_Wrapper_Type) is
   begin
      for I in This.Page_Handler_Registry'Range loop
         if This.Page_Handler_Registry(I).Is_Initialized /= False then
            Text_IO.Put_Line("Cleaning the temp files of " & Natural'Image(I));
            This.Page_Handler_Registry(I).Clean;
         end if;
      end loop;
   end Finalize;
   
   procedure registra_mappa_quartiere(This : in out WebServer_Wrapper_Type; data: String;  quartiere : Natural) is
      TmpID : String := Natural'Image(quartiere);
      StringID : String := TmpID(TmpID'First+1 .. TmpID'Last);
   begin
      This.Page_Handler_Registry(quartiere).Init(quartiere, data);
      Text_IO.Put_Line("Activating /quartiere" & StringID);
      Services.Dispatchers.URI.Register(This.Root, "/quartiere" & StringID, This.Page_Handler_Registry(quartiere), True);
      Server.Set(This.WS, This.Root);
   end registra_mappa_quartiere;

   procedure invia_aggiornamento(This : in out WebServer_Wrapper_Type; data: String; quartiere: Natural) is
   begin
      Net.WebSocket.Registry.Send (This.Rcp, data);
   end invia_aggiornamento;

   procedure Init(This : in out WebServer_Wrapper_Type) is
      MyHome_Page : Home_Page_Handler;
      JS_Compiler : JS_Page_Compiler_Handler;
   begin
      AWS.Config.Set.Reuse_Address(This.WsConfig, True);
      AWS.Config.Set.WWW_Root(This.WsConfig,"www_data");
      AWS.Config.Set.Admin_URI(This.WsConfig,"/admin_aws");
      AWS.Config.Set.Admin_Password(This.WsConfig, "f3378e86bbcb838a242ab29627425b93");
      AWS.Config.Set.Status_Page(This.WsConfig, Admin_Dir & "/aws_status.thtml");
      AWS.Config.Set.Up_Image(This.WsConfig,Admin_Dir & "/aws_up.png");
      AWS.Config.Set.Down_Image(This.WsConfig,Admin_Dir & "/aws_down.png");
      AWS.Config.Set.Logo_Image(This.WsConfig,Admin_Dir & "/aws_logo.png");

      Text_IO.Put_Line
        ("Call me on port" & Positive'Image (AWS.Default.Server_Port));

      Services.Dispatchers.URI.Register_Default_Callback(This.Root, AWS.Dispatchers.Callback.Create(AWS.Services.Page_Server.Callback'Access));
      Services.Dispatchers.URI.Register(This.Root, "/", MyHome_Page);
      Services.Dispatchers.URI.Register(This.Root, "/we_js/", JS_Compiler, True);
      Server.Start
        (This.WS, This.Root, This.WsConfig);

      This.Rcp := Net.WebSocket.Registry.Create (URI => "/websock");

      Net.WebSocket.Registry.Control.Start;
      Net.WebSocket.Registry.Register ("/websock", Websocket_Factory'Access);
   end Init;

   function Get_Max_Partitions(This : in WebServer_Wrapper_Type) return Integer is
   begin 
      return This.Max_Partitions;
   end Get_Max_Partitions;

   function Get_Cur_Partitions(This : in WebServer_Wrapper_Type) return Integer is
   begin
      return This.Cur_Registered_Partitions;
   end Get_Cur_Partitions;

   -- procedure Clean(This : in out WebServer_Wrapper_Type) is
   -- begin
      
   -- end Clean;

   procedure Shutdown(This : in out WebServer_Wrapper_Type) is
   begin 
      Server.Shutdown(This.WS);
   end Shutdown; 

   protected body Remote_Proxy_Type is
   
      procedure registra_mappa_quartiere(data: String;  quartiere : Natural) is
      begin
         WS_Wrapper.registra_mappa_quartiere(data, quartiere);
      end registra_mappa_quartiere;

      procedure invia_aggiornamento(data: String; quartiere: Natural) is
      begin
         WS_Wrapper.invia_aggiornamento(data, quartiere);
      end invia_aggiornamento;

      procedure Init is
      begin
         WS_Wrapper.Init;
      end Init;

      procedure Shutdown is
      begin 
         WS_Wrapper.Shutdown;
      end Shutdown; 

   end Remote_Proxy_Type;

end WebServer;
