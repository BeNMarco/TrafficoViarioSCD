with Ada.Text_IO;

with strade_e_incroci_common;
with remote_types;
with resource_map_inventory;
with risorse_mappa_utilities;
with the_name_server;
with mailbox_risorse_attive;

use Ada.Text_IO;

use strade_e_incroci_common;
use remote_types;
use resource_map_inventory;
use risorse_mappa_utilities;
use the_name_server;
use mailbox_risorse_attive;

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

   procedure synchronization_with_delta is
   begin
      get_synchronization_tasks_partition_object.registra_task;
      synchronization_tasks_partitions.wait_task_partitions;
      get_synchronization_tasks_partition_object.reset;
   end synchronization_with_delta;

   protected body location_abitanti is
      procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance) is
      begin
         percorsi(id_abitante):= new route_and_distance'(percorso);
      end set_percorso_abitante;
   end location_abitanti;

   function get_estremi_incroci(id_urbana: Positive) return estremi_urbane is
      estremi: estremi_urbana;
      return_estremi: estremi_urbane;
   begin
      estremi:= get_server_gps.get_estremi_urbana(get_id_quartiere,id_urbana);
      if estremi(1).get_id_quartiere_estremo_urbana/=0 then
         return_estremi(1):= get_id_risorsa_quartiere(estremi(1).get_id_quartiere_estremo_urbana,estremi(1).get_id_incrocio_estremo_urbana);
      else
         return_estremi(1):= null;
      end if;
      if estremi(2).get_id_quartiere_estremo_urbana/=0 then
         return_estremi(2):= get_id_risorsa_quartiere(estremi(2).get_id_quartiere_estremo_urbana,estremi(2).get_id_incrocio_estremo_urbana);
      else
         return_estremi(2):= null;
      end if;
      return return_estremi;
   end;

   task body core_avanzamento_urbane is
      id_task: Positive;--mail_box: ptr_resource_segmento_strada:= resource;
      mailbox: ptr_resource_segmento_urbana;
      estremi_incroci: estremi_urbane;
   begin
      Put_Line("waiting task");
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_urbane_segmento_resources(id);
      end configure;

      wait_settings_all_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi
      estremi_incroci:= get_estremi_incroci(id_task); -- DOPO la wait sicuramente i riferimenti remoti sono settati

      -- BEGIN LOOP
      synchronization_with_delta;
      -- aspetta che finiscano gli incroci
      if estremi_incroci(1)/=null then
         estremi_incroci(1).wait_turno;
      end if;
      if estremi_incroci(2)/=null then
         estremi_incroci(2).wait_turno;
      end if;
      -- fine wait; gli incroci hanno fatto l'avanzamento
      if mailbox.there_are_pedoni_or_bici_to_move then -- muovi pedoni
         delay 3.0; --simulazione lavoro
      end if;
      if mailbox.there_are_autos_to_move then -- muovi pedoni
         delay 3.0; --simulazione lavoro
      end if;
      mailbox.delta_terminate;
      -- set all entità passive a TRUE
      -- END LOOP;

      Put_Line(Positive'Image(id_task));
   end core_avanzamento_urbane;

   task body core_avanzamento_ingressi is
      id_task: Positive;--mail_box: ptr_resource_segmento_strada:= resource;
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
      synchronization_with_delta;
      resource_main_strada.wait_turno;
      --quando l'abitante è arrivato occorre invocare l'asincrono abitante_is_arrived del tipo del quartiere del luogo arrivo che muoverà nuovamente l'abitante
      -- end loop;

      Put_Line(Positive'Image(id_task));
   end core_avanzamento_ingressi;

   task body core_avanzamento_incroci is
      id_task: Positive;--mail_box: ptr_resource_segmento_strada:= resource;
      mailbox: ptr_resource_segmento_incrocio;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_incroci_segmento_resources(id);
      end configure;

      wait_settings_all_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      -- loop
      synchronization_with_delta;
      Put_Line("inizio lavoto" & Positive'Image(id_task));
      if id_task=9 then
         delay 4.0; --simula lavoro
      else
         delay 15.0;
      end if;

      mailbox.delta_terminate;

      Put_Line("fine lavoro" & Positive'Image(id_task));
      -- end loop;

      Put_Line(Positive'Image(id_task));
   end core_avanzamento_incroci;

   task body core_avanzamento_rotonde is
      id_task: Positive;--mail_box: ptr_resource_segmento_strada:= resource;
      mailbox: ptr_resource_segmento_rotonda;
   begin
      accept configure(id: Positive) do
         id_task:= id;
         mailbox:= get_rotonde_segmento_resources(id);
      end configure;

      wait_settings_all_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      -- loop
      synchronization_with_delta;
      -- end loop;

      Put_Line(Positive'Image(id_task));
   end core_avanzamento_rotonde;

begin
   configure_tasks;
end risorse_strade_e_incroci;
