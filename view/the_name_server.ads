with remote_types;

use remote_types;

package the_name_server is
   pragma Remote_Call_Interface;

   procedure registra_webserver(my_web: Access_WebServer_Remote_Interface);

   function get_webServer return Access_WebServer_Remote_Interface;

   function get_num_quartieri return Integer;

private

   web: Access_WebServer_Remote_Interface:= null;
   num_quartieri : Integer := 4;

end the_name_server;
