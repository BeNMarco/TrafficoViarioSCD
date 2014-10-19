with ada.Text_IO;

with data_quartiere;
with the_name_server;
with remote_types;
with partition_name;

use Ada.Text_IO;

use data_quartiere;
use the_name_server;
use remote_types;
use partition_name;

package body synchronization_task_partition is

   protected body synchronization_tasks is
      entry registra_task(id: Positive) when num_task_to_go=0 is
      begin
         num_task_ready:= num_task_ready+1;
         if num_task_ready=get_num_task then
            num_task_ready:= 0;
            global_synch_obj.all_task_partition_are_ready(get_id_quartiere);
            --log_mio.write_task_arrived("i");
            --Put_Line(Positive'Image(id));
         end if;
      end registra_task;

      procedure wake is
         id: Positive:= get_id_quartiere;
      begin
         awake:= True;
         --Open(File => OutFile, Name => str_quartieri'Image(s) & "_wake_log.txt", Mode => Append_File);
         --Put_Line(OutFile, "w");
         --Close(OutFile);
      end wake;

      entry wait_tasks_partitions when awake is
      begin
         num_task_to_go:= num_task_to_go+1;
         if num_task_to_go=get_num_task then
            num_task_to_go:= 0;
            awake:= False;
            --global_synch_obj.last_task_partition_ready;
            --global_synch_obj.wait_awake_all_partitions;
         end if;
      end wait_tasks_partitions;

   end synchronization_tasks;


end synchronization_task_partition;
