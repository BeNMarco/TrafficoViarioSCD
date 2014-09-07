with remote_types;

use remote_types;

package the_name_server is
   pragma Remote_Call_Interface;

   procedure registra_webserver(my_web: Access_WebServer_Wrapper_Interface);

   function get_webServer return Access_WebServer_Wrapper_Interface;

private

   web: Access_WebServer_Wrapper_Interface:= null;

end the_name_server;
