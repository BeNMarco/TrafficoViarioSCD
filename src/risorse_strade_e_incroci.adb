with Ada.Text_IO;

with strade_e_incroci_common;
with remote_types;
with resource_map_inventory;
with risorse_mappa_utilities;

use Ada.Text_IO;

use strade_e_incroci_common;
use remote_types;
use resource_map_inventory;
use risorse_mappa_utilities;

package body risorse_strade_e_incroci is

   procedure configure_tasks is
   begin
      for index_strada in get_from_urbane..get_to_urbane loop
         task_urbane(index_strada).configure(id => index_strada, resource => urbane_segmento_resources(index_strada));
      end loop;

      for index_strada in get_from_ingressi..get_to_ingressi loop
         task_ingressi(index_strada).configure(id => index_strada, resource => ingressi_segmento_resources(index_strada));
      end loop;

      for index_incrocio in get_from_incroci_a_4..get_to_incroci_a_4 loop
         task_incroci(index_incrocio).configure(id => index_incrocio, resource => incroci_a_4_segmento_resources(index_incrocio));
      end loop;

      for index_incrocio in get_from_rotonde_a_4..get_to_rotonde_a_4 loop
         task_rotonde(index_incrocio).configure(id => index_incrocio, resource => rotonde_a_4_segmento_resources(index_incrocio));
      end loop;

      for index_incrocio in get_from_incroci_a_3..get_to_incroci_a_3 loop
         task_incroci(index_incrocio).configure(id => index_incrocio, resource => incroci_a_3_segmento_resources(index_incrocio));
      end loop;

      for index_incrocio in get_from_rotonde_a_3..get_to_rotonde_a_3 loop
         task_rotonde(index_incrocio).configure(id => index_incrocio, resource => rotonde_a_3_segmento_resources(index_incrocio));
      end loop;

   end;

   protected body location_abitanti is
      procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance) is
      begin
         percorsi(id_abitante):= new route_and_distance'(percorso);
      end set_percorso_abitante;
   end location_abitanti;

   task body core_avanzamento_urbane is
      id_task: Positive;--mail_box: ptr_resource_segmento_strada:= resource;
      mailbox: ptr_resource_segmento_strada;

   begin
      accept configure(id: Positive; resource: ptr_resource_segmento_strada) do
         id_task:= id;
         mailbox:= resource;
      end configure;

      wait_settings_all_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      Put_Line(Positive'Image(id_task));
   end core_avanzamento_urbane;

begin
   configure_tasks;
end risorse_strade_e_incroci;
