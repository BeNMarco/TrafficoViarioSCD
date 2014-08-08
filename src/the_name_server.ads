with remote_types;

use remote_types;

package the_name_server is
   pragma Remote_Call_Interface;

   procedure registra_server_gps(my_gps: ptr_gps_interface);

   procedure registra_server_cache_abitanti(cache: ptr_cache_abitanti_interface);

   function get_server_gps return ptr_gps_interface;

   function get_server_cache_abitanti return ptr_cache_abitanti_interface;

private

   server_cache: ptr_cache_abitanti_interface:= null;
   gps: ptr_gps_interface:= null;


end the_name_server;
