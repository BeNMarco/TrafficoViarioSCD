with remote_types;

use remote_types;

package the_name_server is
   pragma Remote_Call_Interface;

   procedure registra_server_gps(my_gps: ptr_gps_interface);

   procedure registra_server_cache_abitanti(cache: ptr_cache_abitanti_interface);

   procedure registra_server_posizione_abitanti_quartiere(gps_abitanti_quartieri: ptr_rt_posizione_abitanti_quartieri);

   function get_server_gps return ptr_gps_interface;

   function get_server_cache_abitanti return ptr_cache_abitanti_interface;

   function get_server_abitanti_quartiere return ptr_rt_posizione_abitanti_quartieri;

private

   server_cache: ptr_cache_abitanti_interface:= null;
   gps: ptr_gps_interface:= null;
   gps_abitanti: ptr_rt_posizione_abitanti_quartieri:= null;

end the_name_server;
