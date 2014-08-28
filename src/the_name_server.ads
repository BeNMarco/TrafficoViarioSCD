with remote_types;
with global_data;
with partition_name;

use remote_types;
use global_data;
use partition_name;

package the_name_server is
   pragma Remote_Call_Interface;

   procedure registra_server_gps(my_gps: ptr_gps_interface);

   function get_server_gps return ptr_gps_interface;

   procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites);

   function get_ref_rt_quartieri return registro_quartieri;

   procedure registra_local_synchronized_obj(id_quartiere: Positive; obj: ptr_rt_synchronization_tasks);

   function get_ref_local_synchronized_obj return registro_local_synchronized_obj;

   procedure registra_synchronization_tasks_object(obj: ptr_rt_task_synchronization);

   procedure stam;

   function get_synchronization_tasks_object return ptr_rt_task_synchronization;

   type risorse_quartieri is array(Positive range <>) of access set_resources;

   procedure registra_risorse_quartiere(id_quartiere: Positive; set: set_resources);

   function get_id_risorsa_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_segmento;

   procedure registra_gestore_semafori(id_quartiere: Positive; handler_semafori_quartiere: ptr_rt_handler_semafori_quartiere);
   function get_gestori_quartiere return handler_semafori;

   function get_id_mappa return str_quartieri;

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

   protected registro_gestori_semafori is
      procedure registra_gestore_semafori(id_quartiere: Positive; handler_semafori_quartiere: ptr_rt_handler_semafori_quartiere);
      function get_gestori_quartiere return handler_semafori;
   private
      registro: handler_semafori(1..num_quartieri);
   end registro_gestori_semafori;

   protected get_my_mappa is
      procedure registra_mappa(id: out Positive);
   private
      num_mappa: Natural:=0;
   end get_my_mappa;

   protected registro_local_synchronized_objects is
      procedure registra_local_synchronized_obj(id_quartiere: Positive; obj: ptr_rt_synchronization_tasks);
      function get_ref_local_synchronized_obj return registro_local_synchronized_obj;
   private
      registro: registro_local_synchronized_obj(1..num_quartieri);
   end registro_local_synchronized_objects;

   gps: ptr_gps_interface:= null;

   task_synchronization_obj: ptr_rt_task_synchronization:= null;

end the_name_server;
