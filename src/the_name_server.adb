
package body the_name_server is

   procedure registra_server_gps(my_gps: ptr_gps_interface) is
   begin
      gps:= my_gps;
   end registra_server_gps;

   procedure registra_server_cache_abitanti(cache: ptr_cache_abitanti_interface) is
   begin
      server_cache:= cache;
   end registra_server_cache_abitanti;

   procedure registra_server_posizione_abitanti_quartiere(gps_abitanti_quartieri: ptr_rt_posizione_abitanti_quartieri) is
   begin
      gps_abitanti:= gps_abitanti_quartieri;
   end registra_server_posizione_abitanti_quartiere;

   function get_server_abitanti_quartiere return ptr_rt_posizione_abitanti_quartieri is
   begin
      loop
         delay 1.0;
         exit when gps_abitanti/=null;
      end loop;
      return gps_abitanti;
   end get_server_abitanti_quartiere;

   function get_server_gps return ptr_gps_interface is
   begin
      loop
         delay 1.0;
         exit when gps/=null;
      end loop;
      return gps;
   end get_server_gps;

   function get_server_cache_abitanti return ptr_cache_abitanti_interface is
   begin
      loop
         delay 1.0;
         exit when server_cache/=null;
      end loop;
      return server_cache;
   end get_server_cache_abitanti;

end the_name_server;
