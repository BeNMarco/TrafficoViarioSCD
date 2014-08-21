with remote_types;

use remote_types;

package synchronized_task_partitions is

   protected type task_synchronization is new rt_task_synchronization with
      entry all_task_partition_are_ready;
      entry wait_task_partitions;
      procedure reset;
   private
      num_partition_ready: Natural:= 0;
      num_reset: Natural:= 0;
   end task_synchronization;

   type ptr_task_synchronization is access all task_synchronization;

end synchronized_task_partitions;
