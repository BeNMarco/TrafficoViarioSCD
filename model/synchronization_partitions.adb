with Ada.Text_IO;

with global_data;
with the_name_server;
with data_quartiere;
with handle_semafori;

use Ada.Text_IO;

use global_data;
use the_name_server;
use data_quartiere;
use handle_semafori;

package body synchronization_partitions is

   procedure create_semafori is
   begin
      semafori_quartiere_obj:= new handler_semafori_quartiere;
   end create_semafori;

   protected body synchronization_partitions_type is

      procedure clean_new_partition(clean_registry: registro_quartieri) is
      begin
         for i in clean_registry'Range loop
            if clean_registry(i)/=null then
               queue(i):= False;
            end if;
         end loop;
         -- per i booleani in temp occorre resettare a False per le
         -- partizioni che sono in remote_quartieri ma non in clean_registry
         for i in 1..num_quartieri loop
            if remote_quartieri(i)/=null then
               -- il quartiere remoto cioè non doveva aspettare
               -- la partizione i
               if clean_registry(i)=null then
                  temp_registro(i):= False;
               end if;
            end if;
         end loop;
      end clean_new_partition;

      procedure set_clean_executed is
      begin
         clean_has_been_executed:= True;
      end set_clean_executed;

      function get_partitions_to_not_wait return boolean_queue is
      begin
         return not_wait_partitions;
      end get_partitions_to_not_wait;

      function is_partition_to_wait(id: Positive) return Boolean is
      begin
         return not not_wait_partitions(id);
      end is_partition_to_wait;

      entry configure_remote_obj(registro: registro_quartieri) when (all_is_synchronized=False or exit_sys) is
      begin
         if exit_sys then
            return;
         end if;
         not_wait_partitions:= (others => False);
         remote_quartieri:= registro;
         for i in 1..num_quartieri loop
            if i/=get_id_quartiere and remote_quartieri(i)/=null then
               can_be_open_ready_task_queue:= True;
            end if;
         end loop;
         Put_Line("cfg quart " & Boolean'Image(can_be_open_ready_task_queue) & " " & Positive'Image(get_id_quartiere));
      end configure_remote_obj;

      procedure resynch_new_partition is
      begin
         -- controlla la lunghezza della coda degli overlap
         -- se 0 riapri la guardia di current_partition_tasks_are_ready
         -- altrimenti sarà l'ultima partizione in overlap a chiudere la guardia
         if new_partition'Count=0 then
            if can_be_open_ready_task_queue then
               current_partition_tasks_are_ready:= True;
            end if;
            new_partition_guard:= False;
         else
            new_partition_guard:= True;
         end if;
         Put_Line("resynch current task guard" & Boolean'Image(current_partition_tasks_are_ready) & " " & Boolean'Image(can_be_open_ready_task_queue) & " " & Positive'Image(get_id_quartiere) & " length coda " & Natural'Image(new_partition'Count));

      end resynch_new_partition;

      entry new_partition(id: Positive; registro_q_remoto: registro_quartieri) when (new_partition_guard or exit_sys) is
      begin
         if exit_sys then
            return;
         end if;
         if new_partition'Count=0 then
            if can_be_open_ready_task_queue then
               current_partition_tasks_are_ready:= True;
            end if;
            new_partition_guard:= False;
         end if;
         requeue partition_is_ready;
      end new_partition;

      entry partition_is_ready(id: Positive; registro_q_remoto: registro_quartieri) when (current_partition_tasks_are_ready or exit_sys) is
         segnale: Boolean:= True;
      begin

         Put_Line("ENTRY " & Positive'Image(id) & " in quartiere " & Positive'Image(get_id_quartiere));

         if exit_sys then
            return;
         end if;
         -- a new partition
         if remote_quartieri(id)=null then
            Put_Line("go to requeue " & Positive'Image(id) & " " & Positive'Image(get_id_quartiere));
            requeue new_partition;
         end if;
         Put_Line("contENTRY " & Positive'Image(id) & " in quartiere " & Positive'Image(get_id_quartiere));

         --for i in 1..num_quartieri loop
         --   -- se A vede B => B vede A  MENTRE se A non vede B => non è detto che B non vede A
         --   if registro_q_remoto(i)=null and remote_quartieri(i)/=null then
         --     not_wait_partitions(i):= True;
         --   end if;
         --end loop;

         -- viene messo a False il sincronizzatore
         -- questo per le partizioni che al delta precedente c'erano non è rilevante
         -- mentre per le partizioni nuove dal delta precedente potevano essere in coda
         -- new_partition con valore di sincronizzazione forzato a True per permettere
         -- ad altre partizioni di procedere comunque anche se la partizioni nuova era
         -- in attesa su qualche altra partizione

         -- NOOOOOOOOO: -> DEADLOCK get_synchronizer_quartiere(id).partition_is_synchronized(get_id_quartiere,False);

         queue(id):= True;

         -- OCCORRE CONTROLLARE LE CONDIZIONI PER LA CHIUSURA DELLA GUARDIA
         -- UNA PARTIZIONE POTREBBE ESSERE NUOVA E IN ATTESA SU UN ALTRO QUARTIERE
         -- QUINDI NON ARRIVARE MAI QUI AD ESEGUIRE LA ENTRY CORRENTE NEL DELTA CORRENTE
         -- QUINDI LA GUARDIA VA CHIUSA COMUNQUE
         declare
            switch: Boolean:= False;
            -- get_ref_quartiere(id).get_saved_partitions è proprio registro_q_remoto
            -- dato che il quartiere remoto sta eseguendo l'entry corrente
            quartieri: registro_quartieri:= registro_q_remoto;--get_ref_quartiere(id).get_saved_partitions;
         begin
            for i in 1..num_quartieri loop
               -- per il caso quartieri(i)/=null and remote_quartieri(i)=null si
               -- avrà che il quartiere in questione non vede una nuova partizione
               -- che il remoto vede ma questo non ha importanza dato che i quartieri
               -- che entrano nel registro vengono fatti uscire dalla coda
               if quartieri(i)=null and remote_quartieri(i)/=null then
                  temp_registro(i):= True;
                  not_wait_partitions(i):= True;
                  Put_Line("ENTRY temp registro TRUE on " & Positive'Image(i) & " quartiere " & Positive'Image(get_id_quartiere));
               end if;
            end loop;

            for i in 1..num_quartieri loop
               if i/=get_id_quartiere and then remote_quartieri(i)/=null then
                  -- temp_registro(i) se True significa che il quartiere chiamante
                  -- la entry può avere in sospensione il quartiere nuovo
                  -- quindi ai fini della chiusura della guardia corrente
                  -- non è rilevante
                  -- sono rilevanti solo tutti quei quartieri visibili a tutti
                  -- gli altri
                  if queue(i)=False and temp_registro(i)=False then
                     segnale:= False;
                     Put_Line("ENTRY nega segnale");
                  end if;
               end if;
            end loop;

            if segnale then
               Put_Line("segnale TRUE " & Positive'Image(get_id_quartiere));
               for i in 1..num_quartieri loop
                  if temp_registro(i)=False then
                     queue(i):= False;
                  else
                     -- la partizione i entra in gioco al delta successivo
                     -- dato che gli si chiude la guardia alla fine dell'iterazione
                     -- questa partizione potrebbe essere in attesa su questa entry e
                     -- si troverebbe la guardia bloccata quindi per far andare avanti il
                     -- sistema
                     null;
                  end if;
               end loop;
               temp_registro:= (others => False);
               -- CHIUSURA DELLA GUARDIA
               current_partition_tasks_are_ready:= False;
               all_is_synchronized:= True;
               -- LIBERAZIONE DEI SEMAFORI SUL QUARTIERE IN QUESTIONE DATO CHE
               -- SONO ARRIVATE TUTTE LE PARTIZIONI RILEVANTI

           --             Put_Line("ENTRY PRIMA SEMAFORI " & Positive'Image(id) & " in quartiere " & Positive'Image(get_id_quartiere));

               -- CAMBIO VERSO SEMAFORI
            end if;
         end;
         Put_Line("END ENTRY " & Boolean'Image(current_partition_tasks_are_ready) & " in quartiere " & Positive'Image(get_id_quartiere));

      end partition_is_ready;

      procedure set_quartiere_synchro(bool: Boolean) is
      begin
         all_is_synchronized:= bool;
         if bool=False then
            clean_has_been_executed:= False;
         end if;
      end set_quartiere_synchro;

      procedure exit_system is
      begin
         exit_sys:= True;
      end exit_system;

      entry update_semafori when (current_partition_tasks_are_ready=False or exit_sys) is
      begin
         if exit_sys then
            return;
         end if;
         semafori_quartiere_obj.set_num_delta_semafori(semafori_quartiere_obj.get_num_delta_semafori+1);
         if semafori_quartiere_obj.get_id_turno=1 or else semafori_quartiere_obj.get_id_turno=3 then
            if num_delta_semafori=semafori_quartiere_obj.get_num_delta_semafori then
               semafori_quartiere_obj.set_num_delta_semafori(0);
               semafori_quartiere_obj.change_semafori;
               semafori_quartiere_obj.set_id_turno(semafori_quartiere_obj.get_id_turno+1);
               -- viene settato a True il semaforo dei bipedi
               semafori_quartiere_obj.change_semafori_bipedi;
            end if;
         else
            -- id_turno=2 or 4
            if num_delta_semafori_bipedi=semafori_quartiere_obj.get_num_delta_semafori then
               semafori_quartiere_obj.set_num_delta_semafori(0);
               semafori_quartiere_obj.set_id_turno(semafori_quartiere_obj.get_id_turno+1);
               if semafori_quartiere_obj.get_id_turno=5 then
                  semafori_quartiere_obj.set_id_turno(1);
               end if;
               -- viene settato a False il semaforo dei bipedi
               semafori_quartiere_obj.change_semafori_bipedi;
            end if;
         end if;
      end update_semafori;

      --function is_a_new_partition return Boolean is
      --begin
      --   for i in 1..num_quartieri loop
      --      if remote_quartieri(i)/=null then
      --         declare
      --            switch: Boolean:= False;
      --            reg: registro_quartieri:= get_ref_quartiere(i).get_saved_partitions;
      --         begin
      --            -- se il registro è stato settato almeno una volta nel quartiere i
      --            for i in reg'Range loop
      --               if reg(i)/=null then
      --                  switch:= True;
      --               end if;
      --            end loop;
      --            -- se la partizione corrente è una nuova partizione per il
      --            -- quartiere i allora ritorna yes e va ad aprime quindi la guardia wait_synch_quartiere
      --            if switch and reg(get_id_quartiere)=null then
      --               return True;
      --            end if;
      --         end;
      --      end if;
      --   end loop;
      --   return False;
      --end is_a_new_partition;

      entry wait_synch_quartiere(from_quartiere: Positive) when (all_is_synchronized and clean_has_been_executed) or exit_sys is --(all_is_synchronized or is_a_new_partition) or exit_sys is
         segnale: Boolean:= True;
      begin
         if exit_sys then
            return;
         end if;
         -- deve chiudere la guardia all_is_synchronized quando tutti i quartieri
         -- interessati hanno eseguito la corrente entry
         --if all_is_synchronized then
         Put_Line("all is synchronized " & Positive'Image(get_id_quartiere));
         waiting_queue(from_quartiere):= True;
         for i in 1..num_quartieri loop
            -- qui la chiamata is_a_new_quartiere è coerente con il registro del quartiere chiamante
            if remote_quartieri(i)/=null and i/=get_id_quartiere then
               if waiting_queue(i)=True or else get_ref_quartiere(from_quartiere).is_a_new_quartiere(i) then
                  null;
               else
                  Put_Line("on " & Positive'Image(get_id_quartiere) & " FALSE CAUSA " & Positive'Image(i));
                  segnale:= False;
               end if;
            end if;
         end loop;
         Put_Line("segnale on " & Positive'Image(get_id_quartiere) & " vale " & Boolean'Image(segnale));
         if segnale then
            waiting_queue:= (others => False);
            all_is_synchronized:= False;
            clean_has_been_executed:= False;
         end if;
         --else
         --   Put_Line("new_partition " & Positive'Image(get_id_quartiere));
            -- is_a_new_partition vale True
         --   null;
            -- non fa niente dato che la guardia all_is_synchronized è gia False
         --end if;
      end wait_synch_quartiere;

   end synchronization_partitions_type;


end synchronization_partitions;
