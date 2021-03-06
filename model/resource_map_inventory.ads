with data_quartiere;
with strade_e_incroci_common;
with remote_types;
with global_data;
with the_name_server;
with risorse_mappa_utilities;
with synchronization_task_partition;
with mailbox_risorse_attive;
--with handle_semafori;
--with wait_configuration_quartieri;
with Ada.Exceptions;
--with synchronization_partitions;

use data_quartiere;
use strade_e_incroci_common;
use remote_types;
use global_data;
use the_name_server;
use risorse_mappa_utilities;
use synchronization_task_partition;
use mailbox_risorse_attive;
--use handle_semafori;
--use wait_configuration_quartieri;
use Ada.Exceptions;
--use synchronization_partitions;

package resource_map_inventory is
   
   function get_synchronization_tasks_partition_object return ptr_synchronization_tasks;

   type ptr_strade_urbane_features is access all strade_urbane_features;

   procedure configure_quartiere;

   --protected type wrap_type_registro_ref_rt_quartieri(num_quartieri: Positive) is
   --   procedure set_registro_ref_rt_quartieri(registro: registro_quartieri);
   --   function get_registro_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites;
   --private
   --   registro_ref_rt_quartieri: registro_quartieri(1..num_quartieri);
   --end wrap_type_registro_ref_rt_quartieri;

   --type ptr_wrap_type_registro_ref_rt_quartieri is access wrap_type_registro_ref_rt_quartieri;
   
   
private     
   
   synchronization_tasks_partition_obj: ptr_synchronization_tasks:= null;
   
   --obj_registro_ref_rt_quartieri: ptr_wrap_type_registro_ref_rt_quartieri:= null;
   --waiting_object_set_conf: ptr_wait_all_quartieri:= null;--:= new wait_all_quartieri;

   gps: ptr_gps_interface:= null;

end resource_map_inventory;
