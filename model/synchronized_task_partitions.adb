with Ada.Text_IO;

with global_data;
with the_name_server;

use Ada.Text_IO;

use global_data;
use the_name_server;

package body synchronized_task_partitions is

   protected body task_synchronization is

      procedure all_task_partition_are_ready(id: Positive) is
      begin
         --Open(File => OutFile,Name => "serverlog.txt", Mode => Append_File);
         --Put_Line(OutFile, "w");
         --Close(OutFile);
         num_partition_ready:= num_partition_ready+1;
         num_delta_semafori_before_change:= num_delta_semafori_before_change+1;
         if id_turno=1 or else id_turno=3 then
            if num_delta_semafori=num_delta_semafori_before_change then
               num_delta_semafori_before_change:= 0;
               if initialized_gestori_semafori=False then
                  gestori_semafori:= get_gestori_quartiere;
                  initialized_gestori_semafori:= True;
               end if;
               for i in gestori_semafori'Range loop
                  gestori_semafori(i).change_semafori;
               end loop;
               id_turno:= id_turno+1;
               for i in gestori_semafori'Range loop
                  gestori_semafori(i).change_semafori_bipedi; -- viene settato a True il semaforo dei bipedi
               end loop;
            end if;
         else
            -- id_turno=2 or 4
            if num_delta_semafori_bipedi=num_delta_semafori_before_change then
               num_delta_semafori_before_change:= 0;
               id_turno:= id_turno+1;
               if id_turno=5 then
                  id_turno:= 1;
               end if;
               -- initialized_gestori_semafori è sicuramente True dato che inizialmente num_versi_changed_semafori_cars vale 0
               for i in gestori_semafori'Range loop
                  gestori_semafori(i).change_semafori_bipedi; -- viene settato a False il semaforo dei bipedi
               end loop;
            end if;
         end if;

         if num_partition_ready=num_quartieri then
            --Open(File => OutFile,Name => "server_log.txt", Mode => Append_File);
            --Put_Line(OutFile, "w");
            if initialize_local_refs=False then
               local_refs:= get_ref_local_synchronized_obj;
               initialize_local_refs:= True;
            end if;
            for i in local_refs'Range loop
               local_refs(i).wake;
            end loop;
            --Put_Line(OutFile, "w");
            --Close(OutFile);
            num_partition_ready:= 0;
         end if;
      end all_task_partition_are_ready;

      --entry wait_awake_all_partitions when all_partition_waked is
      --begin
      --   num_awaked_partitions:= num_awaked_partitions+1;
      --   if num_awaked_partitions=num_quartieri then
      --      num_awaked_partitions:= 0;
      --      all_partition_waked:= False;
      --   end if;
      --end wait_awake_all_partitions;

      --procedure last_task_partition_ready is
      --begin
      --   num_partition_ready_to_resynch:= num_partition_ready_to_resynch+1;
      --   if num_partition_ready_to_resynch=num_quartieri then
      --      all_partition_waked:= True;
      --      num_partition_ready_to_resynch:= 0;
      --  end if;
      --end last_task_partition_ready;

   end task_synchronization;

end synchronized_task_partitions;
