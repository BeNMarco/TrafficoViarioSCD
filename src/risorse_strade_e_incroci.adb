with Ada.Text_IO;

with strade_e_incroci_common;
with remote_types;

use Ada.Text_IO;

use strade_e_incroci_common;
use remote_types;

package body risorse_strade_e_incroci is

   protected body wait_all_quartieri is
      procedure all_quartieri_set is
      begin
         segnale:= True;
      end all_quartieri_set;

      entry wait_quartieri when segnale=True is
      begin
         segnale:= False;
      end wait_quartieri;

      entry wait_all_task_quartieri when segnale is
      begin
         num_task_registrati:= num_task_registrati+1;
         if num_task_registrati=get_num_task then
            segnale:= False;
         end if;
      end wait_all_task_quartieri;

   end wait_all_quartieri;

   function get_min_length_entità(entity: entità) return Float is
   begin
      case entity is
         when pedone_entity => return min_length_pedoni;
         when bici_entity => return min_length_bici;
         when auto_entity => return min_length_auto;
      end case;
   end get_min_length_entità;

   function calculate_max_num_auto(len: Positive) return Positive is
   begin
      --Put_Line(Positive'Image(Positive(Float'Rounding(Float(len)/get_min_length_entità(auto_entity)))));
      return Positive(Float'Rounding(Float(len)/get_min_length_entità(auto_entity)));
   end calculate_max_num_auto;

   function calculate_max_num_pedoni(len: Positive) return Positive is
   begin
      --Put_Line(Positive'Image(Positive(Float'Rounding(Float(len)/get_min_length_entità(auto_entity)))));
      return Positive(Float'Rounding(Float(len)/get_min_length_entità(pedone_entity)));
   end calculate_max_num_pedoni;

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

      waiting_object.wait_all_task_quartieri;
      -- Ora i task e le risorse di tutti i quartieri sono attivi

      Put_Line(Positive'Image(id_task));
   end core_avanzamento_urbane;

   protected body resource_segmento_strada is
      procedure prova is
      begin
      	Put_Line("backtohome");
      end prova;
   end resource_segmento_strada;

end risorse_strade_e_incroci;
