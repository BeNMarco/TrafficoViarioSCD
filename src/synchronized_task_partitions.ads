with remote_types;
with global_data;
with the_name_server;

use remote_types;
use global_data;
use the_name_server;

package synchronized_task_partitions is

   protected type task_synchronization is new rt_task_synchronization with
      procedure all_task_partition_are_ready;
   private
      num_partition_ready: Natural:= 0;
      --num_reset: Natural:= 0;
      gestori_semafori: handler_semafori(1..num_quartieri):= (others => null);  -- non può essere inizializzato ora
      initialized_gestori_semafori: Boolean:= False;
      num_delta_semafori_before_change: Natural:= 0;
      local_refs: registro_local_synchronized_obj(1..num_quartieri):= (others => null);
      initialize_local_refs: Boolean:= False;
   end task_synchronization;

   type ptr_task_synchronization is access all task_synchronization;

end synchronized_task_partitions;
