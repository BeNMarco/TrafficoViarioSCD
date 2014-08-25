with global_data;
with the_name_server;

use global_data;
use the_name_server;

package body synchronized_task_partitions is

   protected body task_synchronization is

      entry all_task_partition_are_ready when num_reset=0 is
      begin
         num_partition_ready:= num_partition_ready+1;
         num_delta_semafori_before_change:= num_delta_semafori_before_change+1;
         if num_delta_semafori=num_delta_semafori_before_change then
            num_delta_semafori_before_change:= 0;
            if initialized_gestori_semafori=False then
               gestori_semafori:= get_gestori_quartiere;
               initialized_gestori_semafori:= True;
            end if;
            for i in gestori_semafori'Range loop
               gestori_semafori(i).change_semafori;
            end loop;
         end if;
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
