with Ada.Text_IO;

with the_name_server;
with remote_types;

use Ada.Text_IO;

use the_name_server;
use remote_types;

package synchronization_task_partition is

   protected type synchronization_tasks is new rt_synchronization_tasks with
      entry registra_task(id: Positive);
      procedure wake;
      entry wait_tasks_partitions;
   private
      num_task_ready: Natural:= 0;
      num_task_to_go: Natural:= 0;
      global_synch_obj: ptr_rt_task_synchronization:= get_synchronization_tasks_object;
      to_reset: Boolean:= False;
      awake: Boolean:= False;
      OutFile: File_Type;
   end synchronization_tasks;

   type ptr_synchronization_tasks is access all synchronization_tasks;

end synchronization_task_partition;
