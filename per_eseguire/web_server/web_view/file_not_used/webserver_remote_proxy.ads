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
use AWS;
use AWS.Config;
use type AWS.Net.Socket_Access;
use AWS.Services.Dispatchers.URI;

use remote_types;

package webserver_remote_proxy is

	protected type WebServer_Remote_Proxy_Type is new WebServer_Wrapper_Interface with
	     
		procedure registra_mappa_quartiere(json: String;  id : Natural);
		procedure invia_aggiornamento(data: String; quartiere: Natural);
		procedure registra_webserver(webS : Access_WebServer_Wrapper);

	private
		WS     : Access_WebServer_Wrapper;
	end WebServer_Remote_Proxy_Type;

   type Access_WebServer_Wrapper is access all WebServer_Wrapper_Type;

end webserver_remote_proxy;
