with global_data;

use global_data;

package body synchronized_task_partitions is

   protected body task_synchronization is

      entry all_task_partition_are_ready when num_reset=0 is
      begin
         num_partition_ready:= num_partition_ready+1;
      end all_task_partition_are_ready;

      entry wait_task_partitions when num_partition_ready=num_quartieri is
      begin
         null;
      end wait_task_partitions;

      procedure reset is
      begin
         num_reset:= num_reset+1;
         if num_reset=num_quartieri then
            num_reset:= 0;
            num_partition_ready:= 0;
         end if;
      end reset;

   end task_synchronization;

end synchronized_task_partitions;
