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
with AWS.Services.Dispatchers.URI;
with Ada.Finalization;
with Page_CB;
with Home_Page;
with Districts_Repository;
with the_name_server; use the_name_server;

use Ada;
use Ada.Finalization;
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;
use AWS.Services.Dispatchers.URI;

use remote_types;
use Page_CB;
use Districts_Repository;

package WebServer is

	function get_richiesta_terminazione return Boolean;
	procedure set_richiesta_terminazione(termina: Boolean);

	type WebSocket_Registry_Type is array (Positive range <>) of Net.WebSocket.Registry.Recipient;

	-- Calsse WebServer_Wrapper
	-- Ha l'utilità di gestire l'interazione con il webserver AWS
	-- E' Limited_Controlled in modo da gestire la chiusura del server
	type WebServer_Wrapper_Type(Num : Integer) is new Limited_Controlled and Districts_Repository_Interface with private;

	function get_webserver return WebServer_Wrapper_Type;

	procedure registra_mappa_quartiere(This : in out WebServer_Wrapper_Type; data: string; quartiere : Natural);
	procedure invia_aggiornamento(This : in out WebServer_Wrapper_Type; data: String; quartiere: Natural);

	procedure Init(This : in out WebServer_Wrapper_Type);
	procedure Shutdown(This : in out WebServer_Wrapper_Type);

	function Get_Max_Partitions(This : in WebServer_Wrapper_Type) return Integer;
	function Get_Cur_Partitions(This : in WebServer_Wrapper_Type) return Integer;
	overriding function Get_Districts_Registry(This : in WebServer_Wrapper_Type) return Districts_Registry_Type;

	overriding procedure Finalize(This : in out WebServer_Wrapper_Type);

	
	-- Classe Remote_Proxy_Type
	-- Implementa un'interfaccia remota e fa da proxy per il server sottostante
	protected type Remote_Proxy_Type(Num : Integer) is new WebServer_Remote_Interface with
	     
		procedure registra_mappa_quartiere(data: String; quartiere: Natural);
		procedure invia_aggiornamento(data: String; quartiere: Natural);

    function is_alive return Boolean; 
      
		procedure Init;
		procedure Shutdown;

	private
		-- WS_Wrapper : WebServer_Wrapper_Type := WebServer.get_webserver;
	end Remote_Proxy_Type;

	type Access_Remote_Proxy_Type is access Remote_Proxy_Type'Class;

private 

	type WebServer_Wrapper_Type(Num : Integer) is new Limited_Controlled and Districts_Repository_Interface with 
	record
		Home : Home_Page.Home_Page_Handler(Num);
		Rcp : Net.WebSocket.Registry.Recipient;
		Rcp_Registry : WebSocket_Registry_Type(1 .. Num);
		WS     : Server.HTTP;
		WsConfig : AWS.Config.Object;
   	Root : Services.Dispatchers.URI.Handler;
   	Max_Partitions : Integer := Num;
   	Cur_Registered_Partitions : Integer := 0;
   	Page_Handler_Registry : Districts_Registry_Type(1 .. Num);
	end record;

  Terminazione_Richiesta : Boolean := False;
  WebServerObject : WebServer_Wrapper_Type(get_num_quartieri);

end WebServer;
