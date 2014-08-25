with remote_types;
with global_data;

use remote_types;
use global_data;

package synchronized_task_partitions is

   protected type task_synchronization is new rt_task_synchronization with
      entry all_task_partition_are_ready;
      entry wait_task_partitions;
      procedure reset;
   private
      num_partition_ready: Natural:= 0;
      num_reset: Natural:= 0;
      gestori_semafori: handler_semafori(1..num_quartieri):= (others => null);  -- non può essere inizializzato ora
      initialized_gestori_semafori: Boolean:= False;
      num_delta_semafori_before_change: Natural:= 0;
   end task_synchronization;

   type ptr_task_synchronization is access all task_synchronization;

end synchronized_task_partitions;
