with ada.Text_IO;

with data_quartiere;
with the_name_server;
with remote_types;
with synchronization_partitions;
with strade_e_incroci_common;
with risorse_passive_data;
with System_error;
with System.RPC;
with Ada.Exceptions;

use Ada.Text_IO;

use data_quartiere;
use the_name_server;
use remote_types;
use risorse_passive_data;
use strade_e_incroci_common;
use synchronization_partitions;
use system_error;
use Ada.Exceptions;

package body synchronization_task_partition is

   function get_synchronization_partitions_object return ptr_synchronization_partitions_type is
   begin
      return synchronization_partitions_obj;
   end get_synchronization_partitions_object;

   procedure create_synchronize_partitions_obj is
   begin
      synchronization_partitions_obj:= new synchronization_partitions_type(get_num_quartieri);
      create_semafori;
   end create_synchronize_partitions_obj;

   protected body synchronization_tasks is

      entry registra_task(id: Positive) when (num_task_to_go=0 or exit_sys) is
         error_flag: Boolean:= False;
      begin
         if exit_sys=False then
            num_task_ready:= num_task_ready+1;
            if num_task_ready=get_num_task then
               num_task_ready:= 0;
               declare
                  registro: registro_quartieri:= get_registro_quartieri;
                  there_is_a_new_quartiere: Boolean:= False;
                  only_one_quartiere: Boolean:= True;
                  partition_to_clean: registro_quartieri(1..get_num_quartieri):= (others => null);
               begin

                  for i in registro'Range loop
                     if (registro(i)/=null and i/=get_id_quartiere) and get_quartiere_utilities_obj.is_configured_cache_quartiere(i)=False then
                        declare
                           l_ab: list_abitanti_quartiere:= registro(i).get_all_abitanti_quartiere;
                           l_pe: list_pedoni_quartiere:= registro(i).get_all_pedoni_quartiere;
                           l_bi: list_bici_quartiere:= registro(i).get_all_bici_quartiere;
                           l_au: list_auto_quartiere:= registro(i).get_all_auto_quartiere;
                           gps_ab: ptr_rt_location_abitanti:= registro(i).get_locate_abitanti_quartiere(i);
                        begin
                           get_quartiere_utilities_obj.registra_cfg_quartiere(i,l_ab,l_pe,l_bi,l_au,gps_ab);
                        end;
                        there_is_a_new_quartiere:= True;
                     end if;
                     if registro(i)/=null and i/=get_id_quartiere then
                        only_one_quartiere:= False;
                     end if;
                  end loop;

                  --Put_Line("cofigure remote registro " & Positive'Image(get_id_quartiere));
                  if there_is_a_new_quartiere or first_synch then
                     reconfigure_estremi_urbane;
                  end if;
                  first_synch:= False;

                  pragma warnings(off);
                  synchronization_partitions_obj.configure_remote_obj(registro);
                  pragma warnings(on);


                  get_quartiere_utilities_obj.set_synch_cache(registro);

                  Put_Line("resynch " & Positive'Image(get_id_quartiere));
                  synchronization_partitions_obj.resynch_new_partition;

                  for i in registro'Range loop
                     if i/=get_id_quartiere and then registro(i)/=null then
                        Put_Line("ready? " & Positive'Image(get_id_quartiere) & " on "  & Positive'Image(i));
                        get_synchronizer_quartiere(i).partition_is_ready(get_id_quartiere,registro);
                     end if;
                  end loop;

                  if only_one_quartiere then
                     synchronization_partitions_obj.set_quartiere_synchro(True);
                  end if;

                  pragma warnings(off);
                  synchronization_partitions_obj.update_semafori;
                  pragma warnings(on);

                  -- viene eseguita una pulizia per le risorse che sono nuove
                  -- perchè appunto non viste da tutte e hanno uno stato non
                  -- consistente in queue
                  -- A vede B
                  -- B vede A e C
                  -- C vede A e B
                  -- se B sporca la queue di C; al prossimo giro dato che B era vecchia
                  -- e C nuova; C alla sincronizzazione corrente
                  -- non riesce a ripulire lo stato della coda.
                  -- OCCORRE RIPULIRLO SULLE SOLE PARTIZIONI VECCHIE NON SU QUELLE
                  -- NUOVE IN ATTESA SU ALTRE NUOVE
                  Put_Line("before clean");
                  for i in 1..get_num_quartieri loop
                     if registro(i)/=null and synchronization_partitions_obj.is_partition_to_wait(i) then
                        partition_to_clean(i):= get_ref_quartiere(i);
                     end if;
                  end loop;
                  for i in 1..get_num_quartieri loop
                     if (i/=get_id_quartiere and then registro(i)/=null) and synchronization_partitions_obj.is_partition_to_wait(i)=False then
                        get_synchronizer_quartiere(i).clean_new_partition(partition_to_clean);
                     end if;
                  end loop;
                  synchronization_partitions_obj.set_clean_executed;
                  Put_Line("after clean");

                  for i in registro'Range loop
                     if (i/=get_id_quartiere and then registro(i)/=null) and then synchronization_partitions_obj.is_partition_to_wait(i) then
                        Put_Line("wait " & Positive'Image(get_id_quartiere) & " on "  & Positive'Image(i));
                        get_synchronizer_quartiere(i).wait_synch_quartiere(get_id_quartiere);
                     end if;
                  end loop;

                  if only_one_quartiere then
                     synchronization_partitions_obj.set_quartiere_synchro(False);
                  end if;

                  get_quartiere_utilities_obj.set_quartieri_to_not_wait(synchronization_partitions_obj.get_partitions_to_not_wait);
                  Put_Line("end wait synch " & Positive'Image(get_id_quartiere));

                  -- TO DO controllo se ci sono tutti i quartieri se no setto lo stato di errore
                  awake:= True;
               exception
                  when System.RPC.Communication_Error =>
                     Put_Line("partizione remota non raggiungibile.");
                     log_system_error.set_error(begin_propagazione_errore,error_flag);
                     exit_system;
                  when Error: others =>
                     Put_Line("errore nella sincronizzazione.");
                     --Put_Line(Exception_Information(Error));
                     log_system_error.set_error(begin_propagazione_errore,error_flag);
                     exit_system;
               end;
            end if;
         end if;
      exception
         when System.RPC.Communication_Error =>
            Put_Line("partizione remota non raggiungibile.");
            log_system_error.set_error(begin_propagazione_errore,error_flag);
            exit_system;
         when others =>
            Put_Line("errore nella sincronizzazione.");
            log_system_error.set_error(begin_propagazione_errore,error_flag);
            exit_system;
      end registra_task;

      entry wait_tasks_partitions when (awake or exit_sys) is
      begin
         if exit_sys=False then
            num_task_to_go:= num_task_to_go+1;
            if num_task_to_go=get_num_task then
               num_task_to_go:= 0;
               awake:= False;
            end if;
         end if;
      end wait_tasks_partitions;

      procedure exit_system is
      begin
         exit_sys:= True;
         synchronization_partitions_obj.exit_system;
      end exit_system;

   end synchronization_tasks;
end synchronization_task_partition;
