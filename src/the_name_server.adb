
package body the_name_server is

   procedure registra_server_gps(my_gps: ptr_gps_interface) is
   begin
      gps:= my_gps;
   end registra_server_gps;

   procedure registra_server_cache_abitanti(cache: ptr_cache_abitanti_interface) is
   begin
      server_cache:= cache;
   end registra_server_cache_abitanti;

   function get_server_gps return ptr_gps_interface is
   begin
      return gps;
   end get_server_gps;

   function get_server_cache_abitanti return ptr_cache_abitanti_interface is
   begin
      return server_cache;
   end get_server_cache_abitanti;

end the_name_server;
