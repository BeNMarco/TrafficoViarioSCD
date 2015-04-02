with Ada.Text_IO;

with remote_types;
with global_data;
with the_name_server;
with handle_semafori;
with strade_e_incroci_common;

use Ada.Text_IO;

use remote_types;
use global_data;
use the_name_server;
use handle_semafori;
use strade_e_incroci_common;

package synchronization_partitions is

   procedure create_semafori;

   protected type synchronization_partitions_type(num_quartieri: Positive) is new rt_synchronization_partitions_type with

      entry configure_remote_obj(registro: registro_quartieri);
      procedure resynch_new_partition;

      entry new_partition(id: Positive; registro_q_remoto: registro_quartieri);

      -- remote:
      entry partition_is_ready(id: Positive; registro_q_remoto: registro_quartieri);
      entry wait_synch_quartiere(from_quartiere: Positive);
      --procedure partition_is_synchronized(send_by_id_quartiere: Positive; synch: Boolean);
      --function get_saved_partitions return registro_quartieri;

      procedure set_quartiere_synchro(bool: Boolean);
      entry update_semafori;

      procedure exit_system;
      function is_partition_to_wait(id: Positive) return Boolean;

      procedure clean_new_partition(clean_registry: registro_quartieri);
      procedure set_clean_executed;

      function get_partitions_to_not_wait return boolean_queue;

   private
      all_is_synchronized: Boolean:= False;
      can_be_open_ready_task_queue: Boolean:= False;
      current_partition_tasks_are_ready: Boolean:= False;
      temp_registro: boolean_queue(1..num_quartieri):= (others => False);
      remote_quartieri: registro_quartieri(1..num_quartieri):= (others => null);
      queue: boolean_queue(1..num_quartieri):= (others => False);
      waiting_queue: boolean_queue(1..num_quartieri):= (others => False);
      new_partition_guard: Boolean:= False;

      all_partition_waked: Boolean:= False;
      num_partition_ready: Natural:= 0;
      num_awaked_partitions: Natural:= 0;
      num_partition_ready_to_resynch: Natural:= 0;
      --num_versi_changed_semafori_cars: Natural:= 0;
      id_turno: Positive:= 1; -- può essere 1 => cambio semaforo macchine ,2 => passano i bipedi, 3 => cambia semaforo macchine, 4 => passano i bipedi
      --gestori_semafori: handler_semafori(1..num_quartieri):= (others => null);  -- non può essere inizializzato ora
      initialized_gestori_semafori: Boolean:= False;
      num_delta_semafori_before_change: Natural:= 0;
      --local_refs: registro_local_synchronized_obj(1..num_quartieri):= (others => null);
      initialize_local_refs: Boolean:= False;

      exit_sys: Boolean:= False;
      not_wait_partitions: boolean_queue(1..num_quartieri):= (others => False);
      clean_has_been_executed: Boolean:= False;
   end synchronization_partitions_type;

   type ptr_synchronization_partitions_type is access all synchronization_partitions_type;

private
   semafori_quartiere_obj: ptr_handler_semafori_quartiere:= null;
end synchronization_partitions;
