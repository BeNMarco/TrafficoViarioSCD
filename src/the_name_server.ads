with remote_types;
with global_data;

use remote_types;
use global_data;

package the_name_server is
   pragma Remote_Call_Interface;

   procedure registra_server_gps(my_gps: ptr_gps_interface);

   function get_server_gps return ptr_gps_interface;

   procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites);

   function get_ref_rt_quartieri return registro_quartieri;

private

   protected registro_ref_quartieri is
      procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites);
      function get_ref_rt_quartieri return registro_quartieri;
   private
      registro: registro_quartieri(1..num_quartieri);
   end registro_ref_quartieri;

   gps: ptr_gps_interface:= null;

end the_name_server;
