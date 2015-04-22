with remote_types;
with Ada.Text_IO;
with Ada.Exceptions;
use Ada.Exceptions;

with Ada.Strings.Unbounded;

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
with Ada.Directories; 

with GNATCOLL.JSON;

with Page_CB;
with WebSock_Quartiere_CB;
with WebSock_Mainpage_CB;
with Home_Page;
with JS_Page_Compiler;
with Districts_Repository;

with global_data;
with absolute_path;
with JSON_Helper;

use Page_CB;
use WebSock_Quartiere_CB;
use Home_Page;
use JS_Page_Compiler;
use Districts_Repository;

use Ada;
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;
use GNATCOLL.JSON;

use remote_types;
use absolute_path;

package body WebServer is
   use Ada.Directories;
   use Ada.Text_IO;
   
   Admin_Dir : String := abs_path & "web_view/admin_data";
   WWW_Root : String :=  abs_path & "web_view/www_data";
   WebSocket_Updates_URI : String := "updatesStream";
   MainPage_WebSocket_Updates_URI : String := "mainpageUpdates";
   WebServer_Config_File : String := "data/webserver_config.json";
   Standard_Port : Integer := 12345;

   Traiettorie_FileName : String := "traiettorie.json";
   DescrizioneMappa_FileName : String := "descrizione_mappa.json";

   function get_webserver return Access_WebServer_Wrapper_Type is
   begin
      return WebServerInstance'Access;
   end get_webserver;

   procedure Init(This : in out WebServer_Wrapper_Type) is
      use JSON_Helper;

      JS_Compiler : JS_Page_Compiler_Handler;
      JWebConfig : JSON_Value := Get_Json_Value(Json_File_Name => abs_path & WebServer_Config_File);
      WS_Port : Integer := Get(JWebConfig, "port");
   begin
      if WS_Port = 0 then
        WS_Port := Standard_Port;
      end if;
      
      AWS.Config.Set.Reuse_Address(This.WsConfig, True);
      AWS.Config.Set.WWW_Root(This.WsConfig, abs_path & "web_view/www_data");
      AWS.Config.Set.Admin_URI(This.WsConfig, abs_path & "web_view/admin_aws");
      AWS.Config.Set.Admin_Password(This.WsConfig, "f3378e86bbcb838a242ab29627425b93");
      AWS.Config.Set.Status_Page(This.WsConfig, abs_path & "web_view/" & Admin_Dir & "/aws_status.thtml");
      AWS.Config.Set.Up_Image(This.WsConfig, abs_path & "web_view/" & Admin_Dir & "/aws_up.png");
      AWS.Config.Set.Down_Image(This.WsConfig, abs_path & "web_view/" & Admin_Dir & "/aws_down.png");
      AWS.Config.Set.Logo_Image(This.WsConfig, abs_path & "web_view/" & Admin_Dir & "/aws_logo.png");
      AWS.Config.Set.Server_Port(This.WsConfig, WS_Port);

      This.Home.Set_Districts_Repository(This'Unchecked_Access);

      Services.Dispatchers.URI.Register_Default_Callback(This.Root, AWS.Dispatchers.Callback.Create(AWS.Services.Page_Server.Callback'Access));
      Services.Dispatchers.URI.Register(This.Root, "/", This.Home);
      Services.Dispatchers.URI.Register(This.Root, "/we_js/", JS_Compiler, True);
      begin
         Server.Start(This.WS, This.Root, This.WsConfig);
         Put_Line("Call me on port " & Integer'Image(WS_Port));
      exception
         when Error: others =>
            Put_Line("Unexpected exception: ");
            Put_Line(Exception_Information(Error));
      end;
      
      Net.WebSocket.Registry.Control.Start;

      -- aggiungiamo un websocket per notificare alla pagina principale dell'avvenuta registrazione di un quartiere
      This.MainPage_WebSocket_Recipient := Net.WebSocket.Registry.Create (URI => "/" & MainPage_WebSocket_Updates_URI);

      -- riusiamo il gestore di websocket usato per i quartieri: dobbiamo inviare messaggi semplici
      -- e vogliamo poter chidere la simulazione anche da qui
      Net.WebSocket.Registry.Register ("/" & MainPage_WebSocket_Updates_URI, WebSock_Mainpage_CB.Websocket_Factory'Access);
   end Init;

   --protected body WebServer_Wrapper_Type is
   overriding procedure Finalize(This : in out WebServer_Wrapper_Type) is
   begin
      for I in This.Page_Handler_Registry'Range loop
         if This.Page_Handler_Registry(I).Is_Initialized /= False then
            This.Page_Handler_Registry(I).Clean;
         end if;
      end loop;
      -- Put_Line("Deleting temp file " & WWW_Root & "/" & Traiettorie_FileName);
      -- Delete_File(WWW_Root & "/" & Traiettorie_FileName);
      -- Put_Line("Deleting temp file " & WWW_Root & "/" & DescrizioneMappa_FileName);
      -- Delete_File(WWW_Root & "/" & DescrizioneMappa_FileName);
      -- exception
      --   when Directories.Name_Error => Put_Line("File "&WWW_Root & "/" & DescrizioneMappa_FileName&" not found");
      --   when Directories.Use_Error => Put_Line("Can't delete the file " &WWW_Root & "/" & DescrizioneMappa_FileName);
   end Finalize;
   
   procedure registra_mappa_quartiere(This : in out WebServer_Wrapper_Type; data: String;  quartiere : Natural) is
      TmpID : String := Natural'Image(quartiere);
      StringID : String := TmpID(TmpID'First+1 .. TmpID'Last);
      JData : JSON_Value := Create_Object;
   begin
      This.Page_Handler_Registry(quartiere).Init(quartiere, data);
      Put_Line("Activating /quartiere" & StringID);
      Services.Dispatchers.URI.Register(This.Root, "/quartiere" & StringID, This.Page_Handler_Registry(quartiere), True);
      Server.Set(This.WS, This.Root);

      This.Rcp_Registry(quartiere) := Net.WebSocket.Registry.Create (URI => "/quartiere" & StringID & "/" & WebSocket_Updates_URI);
      Net.WebSocket.Registry.Register ("/quartiere" & StringID & "/" & WebSocket_Updates_URI, Websocket_Factory'Access);
      
      -- notifica dell'avvenuta registrazione
      Set_Field(Val => JData, Field_Name => "type", Field => "update");
      Set_Field(Val => JData, Field_Name => "quartiere", Field => quartiere);

      Net.WebSocket.Registry.Send (This.MainPage_WebSocket_Recipient, Write(JData));

   end registra_mappa_quartiere;

   procedure registra_traiettorie(This : in out WebServer_Wrapper_Type; data: String) is 
      JSON_File : File_Type;
    begin
      Create(File => JSON_File, Mode => Out_File, Name => WWW_Root & "/" & Traiettorie_FileName);
      Put_Line(JSON_File, data);
      Close(JSON_File);
    end registra_traiettorie;

   procedure registra_descrizione_mappa(This : in out WebServer_Wrapper_Type; data: String) is 
      JSON_File : File_Type;
      JSON_File_Name : String := "descrizione_mappa.json";
    begin
      Create(File => JSON_File, Mode => Out_File, Name => WWW_Root & "/" & DescrizioneMappa_FileName);
      Put_Line(JSON_File, data);
      Close(JSON_File);
    end registra_descrizione_mappa;

   procedure invia_aggiornamento(This : in out WebServer_Wrapper_Type; data: String; quartiere: Natural) is
      JData : JSON_Value := Read(Strm => data,
                                 Filename => "debug.txt");
   begin
      --Net.WebSocket.Registry.Send (This.Rcp_Registry(quartiere), data);
      Set_Field(  Val => JData,
                  Field_Name => "type",
                  Field => "update");

      if quartiere in This.Rcp_Registry'Range then
         Net.WebSocket.Registry.Send (This.Rcp_Registry(quartiere), Write(JData));
      end if;
   end invia_aggiornamento;


   procedure notifica_terminazione(This : in out WebServer_Wrapper_Type) is
      JData : JSON_Value := Create_Object;
   begin
      Set_Field(Val => JData, Field_Name => "type", Field => "command");
      Set_Field(Val => JData, Field_Name => "command", Field => "terminated");

      Net.WebSocket.Registry.Send(This.MainPage_WebSocket_Recipient, Write(JData));
      for recipient of This.Rcp_Registry loop
         Net.WebSocket.Registry.Send (recipient , Write(JData));
      end loop;
   end notifica_terminazione;

   procedure notifica_richiesta_terminazione(This : in out WebServer_Wrapper_Type) is
      JData : JSON_Value := Create_Object;
   begin
      Set_Field(Val => JData, Field_Name => "type", Field => "command");
      Set_Field(Val => JData, Field_Name => "command", Field => "termination_requested");

      Net.WebSocket.Registry.Send(This.MainPage_WebSocket_Recipient, Write(JData));
      for recipient of This.Rcp_Registry loop
         Net.WebSocket.Registry.Send (recipient , Write(JData));
      end loop;
   end notifica_richiesta_terminazione;

   -- function get_richiesta_terminazione return Boolean is
   -- begin
   --    -- return Terminazione_Richiesta;
   -- end get_richiesta_terminazione;

   -- procedure set_richiesta_terminazione(termina: Boolean) is
   -- begin
   --    Terminazione_Richiesta := termina;
   -- end set_richiesta_terminazione;

   -- function get_webserver return WebServer_Wrapper_Type is
   -- begin
   --    return WebServerObject;
   -- end get_webserver;

   function Get_Max_Partitions(This : in WebServer_Wrapper_Type) return Integer is
   begin 
      return This.Max_Partitions;
   end Get_Max_Partitions;

   function Get_Cur_Partitions(This : in WebServer_Wrapper_Type) return Integer is
   begin
      return This.Cur_Registered_Partitions;
   end Get_Cur_Partitions;

   function Get_Registered_Districts(This : in WebServer_Wrapper_Type) return Registered_Districts_Type is
   begin
      return This.Home.Get_Registered_Districts;
   end;

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

      procedure registra_descrizione_mappa(data: String) is
      begin
         WS_Wrapper.registra_descrizione_mappa(data);
      end registra_descrizione_mappa;

      procedure registra_traiettorie(data: String) is
      begin
         WS_Wrapper.registra_traiettorie(data);
      end registra_traiettorie;

      procedure invia_aggiornamento(data: String; quartiere: Natural) is
      begin
         WS_Wrapper.invia_aggiornamento(data, quartiere);
      end invia_aggiornamento;

      function is_alive return Boolean is
      begin
         return Alive;
      end is_alive;
      
      procedure Init is
      begin
         WS_Wrapper.Init;
         Alive := True;
      end Init;

      procedure Shutdown is
      begin 
         WS_Wrapper.Shutdown;
      end Shutdown; 

      procedure close_webserver is
      begin
         WS_Wrapper.notifica_terminazione;
         Alive := False;
      end close_webserver;

   end Remote_Proxy_Type;

end WebServer;
