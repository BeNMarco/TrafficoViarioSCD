with data_quartiere;
with the_name_server;
with remote_types;

use data_quartiere;
use the_name_server;
use remote_types;

package body synchronization_task_partition is

   protected body synchronization_tasks is
      entry registra_task when num_task_to_go=0 is
      begin
         num_task_ready:= num_task_ready+1;
         if num_task_ready=get_num_task then
            num_task_ready:= 0;
            get_synchronization_tasks_object.all_task_partition_are_ready;
         end if;
      end registra_task;

      procedure reset is
      begin
         num_task_to_go:= num_task_to_go+1;
         if num_task_to_go=get_num_task then
            num_task_to_go:= 0;
            get_synchronization_tasks_object.reset;
         end if;
      end reset;

   end synchronization_tasks;


end synchronization_task_partition;
