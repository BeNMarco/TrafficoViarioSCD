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

   procedure registra_synchronization_tasks_object(obj: ptr_rt_task_synchronization);

   function get_synchronization_tasks_object return ptr_rt_task_synchronization;

   type risorse_quartieri is array(Positive range <>) of access set_resources;

   procedure registra_risorse_quartiere(id_quartiere: Positive; set: set_resources);

   function get_id_risorsa_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_segmento;

private

   protected registro_ref_quartieri is
      procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites);
      function get_ref_rt_quartieri return registro_quartieri;
   private
      registro: registro_quartieri(1..num_quartieri);
   end registro_ref_quartieri;

   protected registro_risorse_strade is
      procedure registra_risorse_quartiere(id_quartiere: Positive; set: set_resources);
      function get_id_risorsa_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_segmento;
   private
      registro: risorse_quartieri(1..num_quartieri);
   end registro_risorse_strade;

   gps: ptr_gps_interface:= null;

   task_synchronization_obj: ptr_rt_task_synchronization:= null;

end the_name_server;
