with remote_types;
with Ada.Text_IO;
with Ada.Exceptions;
use Ada.Exceptions;

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
with Districts_Repository;

with global_data;

use Page_CB;
use Websock_CB;
use Home_Page;
use JS_Page_Compiler;
use Districts_Repository;

use Ada;
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;

use remote_types;

with absolute_path;
use absolute_path;

package body WebServer is
   
   Admin_Dir : String := abs_path & "web_view/admin_data";
   WWW_Root : String :=  abs_path & "web_view/www_data";
   WebSocket_Updates_URI : String := "updatesStream";
   
   --protected body WebServer_Wrapper_Type is
   overriding procedure Finalize(This : in out WebServer_Wrapper_Type) is
   begin
      for I in This.Page_Handler_Registry'Range loop
         if This.Page_Handler_Registry(I).Is_Initialized /= False then
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

      This.Rcp_Registry(quartiere) := Net.WebSocket.Registry.Create (URI => "/quartiere" & StringID & "/" & WebSocket_Updates_URI);
      Net.WebSocket.Registry.Register ("/quartiere" & StringID & "/" & WebSocket_Updates_URI, Websocket_Factory'Access);

   end registra_mappa_quartiere;

   procedure invia_aggiornamento(This : in out WebServer_Wrapper_Type; data: String; quartiere: Natural) is
   begin
      --Net.WebSocket.Registry.Send (This.Rcp_Registry(quartiere), data);
      if quartiere in This.Rcp_Registry'Range then
         Net.WebSocket.Registry.Send (This.Rcp_Registry(quartiere), data);
      end if;
   end invia_aggiornamento;

   procedure Init(This : in out WebServer_Wrapper_Type) is
      JS_Compiler : JS_Page_Compiler_Handler;
   begin
      AWS.Config.Set.Reuse_Address(This.WsConfig, True);
      AWS.Config.Set.WWW_Root(This.WsConfig, abs_path & "web_view/www_data");
      AWS.Config.Set.Admin_URI(This.WsConfig, abs_path & "web_view/admin_aws");
      AWS.Config.Set.Admin_Password(This.WsConfig, "f3378e86bbcb838a242ab29627425b93");
      AWS.Config.Set.Status_Page(This.WsConfig, abs_path & "web_view/" & Admin_Dir & "/aws_status.thtml");
      AWS.Config.Set.Up_Image(This.WsConfig, abs_path & "web_view/" & Admin_Dir & "/aws_up.png");
      AWS.Config.Set.Down_Image(This.WsConfig, abs_path & "web_view/" & Admin_Dir & "/aws_down.png");
      AWS.Config.Set.Logo_Image(This.WsConfig, abs_path & "web_view/" & Admin_Dir & "/aws_logo.png");
      AWS.Config.Set.Server_Port(This.WsConfig,12345);

      This.Home.Set_Districts_Repository(This'Unchecked_Access);

      Services.Dispatchers.URI.Register_Default_Callback(This.Root, AWS.Dispatchers.Callback.Create(AWS.Services.Page_Server.Callback'Access));
      Services.Dispatchers.URI.Register(This.Root, "/", This.Home);
      Services.Dispatchers.URI.Register(This.Root, "/we_js/", JS_Compiler, True);
      begin
         Server.Start(This.WS, This.Root, This.WsConfig);
         Text_IO.Put_Line("Call me on port 12345");
      exception
         when Error: others =>
            Text_IO.Put_Line("Unexpected exception: ");
            Text_IO.Put_Line(Exception_Information(Error));
      end;
      
      
      Net.WebSocket.Registry.Control.Start;
   end Init;

   function Get_Max_Partitions(This : in WebServer_Wrapper_Type) return Integer is
   begin 
      return This.Max_Partitions;
   end Get_Max_Partitions;

   function Get_Cur_Partitions(This : in WebServer_Wrapper_Type) return Integer is
   begin
      return This.Cur_Registered_Partitions;
   end Get_Cur_Partitions;

   overriding function Get_Districts_Registry(This : in WebServer_Wrapper_Type) return Districts_Registry_Type is
   begin
      return This.Page_Handler_Registry;
   end Get_Districts_Registry;


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
