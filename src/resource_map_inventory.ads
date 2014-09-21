with data_quartiere;
with strade_e_incroci_common;
with remote_types;
with global_data;
with the_name_server;
with risorse_mappa_utilities;
with synchronization_task_partition;
with mailbox_risorse_attive;
with handle_semafori;

use data_quartiere;
use strade_e_incroci_common;
use remote_types;
use global_data;
use the_name_server;
use risorse_mappa_utilities;
use synchronization_task_partition;
use mailbox_risorse_attive;
use handle_semafori;

package resource_map_inventory is

   function get_synchronization_tasks_partition_object return ptr_synchronization_tasks;

   protected type wait_all_quartieri is new rt_wait_all_quartieri with
      procedure all_quartieri_set;
      entry wait_quartieri;
   private
      segnale: Boolean:= False;
   end wait_all_quartieri;

   type ptr_wait_all_quartieri is access wait_all_quartieri;

   type ptr_strade_urbane_features is access all strade_urbane_features;

   function get_quartiere_cfg(id_quartiere: Positive) return ptr_rt_quartiere_utilitites;

private

   registro_ref_rt_quartieri: registro_quartieri(1..num_quartieri);

   waiting_object: ptr_wait_all_quartieri:= new wait_all_quartieri;

   -- server gps
   gps: ptr_gps_interface:= get_server_gps;

   synchronization_tasks_partition: ptr_synchronization_tasks:= new synchronization_tasks;

   semafori_quartiere_obj: ptr_handler_semafori_quartiere:= new handler_semafori_quartiere;

end resource_map_inventory;
