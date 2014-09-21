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

use Ada;
use Ada.Finalization;
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;
use AWS.Services.Dispatchers.URI;

use remote_types;
use Page_CB;

package WebServer is

	type Page_Handler_Registry_Type is array (Positive range <>) of District_Page;

	-- Calsse WebServer_Wrapper
	-- Ha l'utilità di gestire l'interazione con il webserver AWS
	-- E' Limited_Controlled in modo da gestire la chiusura del server
	type WebServer_Wrapper_Type(Num : Integer) is new Limited_Controlled with private;

	procedure registra_mappa_quartiere(This : in out WebServer_Wrapper_Type; data: string; quartiere : Natural);
	procedure invia_aggiornamento(This : in out WebServer_Wrapper_Type; data: String; quartiere: Natural);

	procedure Init(This : in out WebServer_Wrapper_Type);
	procedure Shutdown(This : in out WebServer_Wrapper_Type);

	function Get_Max_Partitions(This : in WebServer_Wrapper_Type) return Integer;
	function Get_Cur_Partitions(This : in WebServer_Wrapper_Type) return Integer;

	overriding procedure Finalize(This : in out WebServer_Wrapper_Type);

	
	-- Classe Remote_Proxy_Type
	-- Implementa un'interfaccia remota e fa da proxy per il server sottostante
	protected type Remote_Proxy_Type(Num : Integer) is new WebServer_Remote_Interface with
	     
		procedure registra_mappa_quartiere(data: String; quartiere: Natural);
		procedure invia_aggiornamento(data: String; quartiere: Natural);

		procedure Init;
		procedure Shutdown;

	private
		WS_Wrapper : WebServer_Wrapper_Type(Num);
	end Remote_Proxy_Type;

	type Access_Remote_Proxy_Type is access Remote_Proxy_Type'Class;

private 

	type WebServer_Wrapper_Type(Num : Integer) is new Limited_Controlled with 
	record
		Rcp : Net.WebSocket.Registry.Recipient;
		WS     : Server.HTTP;
		WsConfig : AWS.Config.Object;
   		Root : Services.Dispatchers.URI.Handler;
   		Max_Partitions : Integer := Num;
   		Cur_Registered_Partitions : Integer := 0;
   		Page_Handler_Registry : Page_Handler_Registry_Type(1 .. Num);
	end record;

end WebServer;
