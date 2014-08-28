with Ada.Text_IO;
--with Ada.Task_Identification;
--with Ada.Dynamic_Priorities;
--with System;

with strade_e_incroci_common;
with remote_types;
with resource_map_inventory;
with risorse_mappa_utilities;
with the_name_server;
with mailbox_risorse_attive;
with synchronization_task_partition;

use Ada.Text_IO;
--use Ada.Task_Identification;
--use Ada.Dynamic_Priorities;
--use System;

use strade_e_incroci_common;
use remote_types;
use resource_map_inventory;
use risorse_mappa_utilities;
use the_name_server;
use mailbox_risorse_attive;
use synchronization_task_partition;

package body risorse_strade_e_incroci is

   procedure configure_tasks is
   begin
      for index_strada in get_from_urbane..get_to_urbane loop
         task_urbane(index_strada).configure(id => index_strada);
      end loop;

      for index_strada in get_from_ingressi..get_to_ingressi loop
         task_ingressi(index_strada).configure(id => index_strada);
      end loop;

      for index_incrocio in get_from_incroci_a_4..get_to_incroci_a_4 loop
         task_incroci(index_incrocio).configure(id => index_incrocio);
      end loop;

      for index_incrocio in get_from_rotonde_a_4..get_to_rotonde_a_4 loop
         task_rotonde(index_incrocio).configure(id => index_incrocio);
      end loop;

      for index_incrocio in get_from_incroci_a_3..get_to_incroci_a_3 loop
         task_incroci(index_incrocio).configure(id => index_incrocio);
      end loop;

      for index_incrocio in get_from_rotonde_a_3..get_to_rotonde_a_3 loop
         task_rotonde(index_incrocio).configure(id => index_incrocio);
      end loop;
   end;

   procedure synchronization_with_delta(id: Positive) is
      synch_obj: ptr_synchronization_tasks:= get_synchronization_tasks_partition_object;
   begin
      synch_obj.registra_task(id);
      synch_obj.wait_tasks_partitions;
   end synchronization_with_delta;

   protected body location_abitanti is
      procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance) is
      begin
         percorsi(id_abitante):= new route_and_distance'(percorso);
      end set_percorso_abitante;
   end location_abitanti;

   task body core_avanzamento_urbane is
      id_task: Positive;
      mailbox: ptr_resource_segmento_urbana;
      array_estremi_strada_urbana: estremi_strada_urbana:= (others => null);
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_urbane_segmento_resources(id);
      end configure;
      -- Put_Line("configurato" & Positive'Image(id_task) & "id quartiere" & Positive'Image(get_id_quartiere));

      wait_settings_all_quartieri;
      array_estremi_strada_urbana:= get_estremi_urbana(id_task);

      -- BEGIN LOOP
      synchronization_with_delta(id_task);
      -- aspetta che finiscano gli incroci
      if array_estremi_strada_urbana(1)/=null then
         array_estremi_strada_urbana(1).wait_turno;
      end if;
      if array_estremi_strada_urbana(2)/=null then
         array_estremi_strada_urbana(2).wait_turno;
      end if;
      -- fine wait; gli incroci hanno fatto l'avanzamento
      if mailbox.there_are_pedoni_or_bici_to_move then -- muovi pedoni
         delay 2.0; --simulazione lavoro
      end if;
      if mailbox.there_are_autos_to_move then -- muovi pedoni
         delay 2.0; --simulazione lavoro
      end if;
      mailbox.delta_terminate;
      -- set all entità passive a TRUE
      -- END LOOP;

      Put_Line("Fine task urbana" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_urbane;

   task body core_avanzamento_ingressi is
      id_task: Positive;
      mailbox: ptr_resource_segmento_ingresso;
      resource_main_strada: ptr_resource_segmento_urbana;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_ingressi_segmento_resources(id);
         resource_main_strada:= get_urbane_segmento_resources(get_ingresso_from_id(id_task).get_id_main_strada_ingresso);
      end configure;

      wait_settings_all_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      -- loop
      synchronization_with_delta(id_task);
      resource_main_strada.wait_turno;
      --quando l'abitante è arrivato occorre invocare l'asincrono abitante_is_arrived del tipo del quartiere del luogo arrivo che muoverà nuovamente l'abitante
      -- end loop;

      Put_Line("Fine task ingresso" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_ingressi;

   task body core_avanzamento_incroci is
      id_task: Positive;
      mailbox: ptr_resource_segmento_incrocio;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_incroci_segmento_resources(id);
      end configure;

      wait_settings_all_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      -- loop
      synchronization_with_delta(id_task);
      delay 5.0;
      mailbox.delta_terminate;
      -- end loop;

      Put_Line("Fine task incrocio" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_incroci;

   task body core_avanzamento_rotonde is
      id_task: Positive;
      mailbox: ptr_resource_segmento_rotonda;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_rotonde_segmento_resources(id);
      end configure;

      wait_settings_all_quartieri;
      Put_Line(Positive'Image(id_task));
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      -- loop
      synchronization_with_delta(id_task);
      -- end loop;

      Put_Line("Fine task" & Positive'Image(id_task) & ",id quartiere" & Positive'Image(get_id_quartiere));
   end core_avanzamento_rotonde;

begin
   configure_tasks;
end risorse_strade_e_incroci;
