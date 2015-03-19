with Ada.Text_IO;

with remote_types;
with global_data;
with the_name_server;

use Ada.Text_IO;

use remote_types;
use global_data;
use the_name_server;

package synchronized_task_partitions is

   protected type task_synchronization(num_quartieri: Positive) is new rt_task_synchronization with
        procedure all_task_partition_are_ready(id: Positive);
      --entry wait_awake_all_partitions;
      --procedure last_task_partition_ready;

   private
      all_partition_waked: Boolean:= False;
      num_partition_ready: Natural:= 0;
      num_awaked_partitions: Natural:= 0;
      num_partition_ready_to_resynch: Natural:= 0;
      --num_versi_changed_semafori_cars: Natural:= 0;
      id_turno: Positive:= 1; -- può essere 1 => cambio semaforo macchine ,2 => passano i bipedi, 3 => cambia semaforo macchine, 4 => passano i bipedi
      gestori_semafori: handler_semafori(1..num_quartieri):= (others => null);  -- non può essere inizializzato ora
      initialized_gestori_semafori: Boolean:= False;
      num_delta_semafori_before_change: Natural:= 0;
      local_refs: registro_local_synchronized_obj(1..num_quartieri):= (others => null);
      initialize_local_refs: Boolean:= False;
      OutFile: File_Type;
   end task_synchronization;

   type ptr_task_synchronization is access all task_synchronization;

end synchronized_task_partitions;
