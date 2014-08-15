with remote_types;

use remote_types;

package the_name_server is
   pragma Remote_Call_Interface;

   procedure registra_server_gps(my_gps: ptr_gps_interface);

   function get_server_gps return ptr_gps_interface;

private

   gps: ptr_gps_interface:= null;

end the_name_server;
