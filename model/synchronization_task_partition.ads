with Ada.Text_IO;

with the_name_server;
with remote_types;
with synchronization_partitions;
with risorse_passive_data;

use Ada.Text_IO;

use the_name_server;
use remote_types;
use synchronization_partitions;
use risorse_passive_data;

package synchronization_task_partition is

   function get_synchronization_partitions_object return ptr_synchronization_partitions_type;

   procedure create_synchronize_partitions_obj;

   protected type synchronization_tasks is
      entry registra_task(id: Positive);
      entry wait_tasks_partitions;

      procedure exit_system(regular: Boolean:= False);
      function is_regular_closure return Boolean;

      entry wait_to_be_last_task;
      procedure task_has_finished;

   private
      regular_exit_sys: Boolean:= False;
      exit_sys: Boolean:= False;
      num_task_ready: Natural:= 0;
      num_task_to_go: Natural:= 0;
      to_reset: Boolean:= False;
      awake: Boolean:= False;

      num: Natural:= 0;
      first_synch: Boolean:= True;
      num_task_arrived: Natural:= 0;
   end synchronization_tasks;

   type ptr_synchronization_tasks is access all synchronization_tasks;
private
   synchronization_partitions_obj: ptr_synchronization_partitions_type:= null;


end synchronization_task_partition;
