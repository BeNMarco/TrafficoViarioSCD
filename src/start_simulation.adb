with Ada.Text_IO;

with mailbox_risorse_attive;
with resource_map_inventory;
with data_quartiere;
with strade_e_incroci_common;
with the_name_server;
with remote_types;
with risorse_passive_data;
with risorse_mappa_utilities;

use Ada.Text_IO;

use mailbox_risorse_attive;
use resource_map_inventory;
use data_quartiere;
use strade_e_incroci_common;
use the_name_server;
use remote_types;
use risorse_passive_data;
use risorse_mappa_utilities;

package body start_simulation is

   procedure abitante_is_arrived(obj: quartiere_entities_life; id_abitante: Positive) is
      resource_locate_abitanti: ptr_location_abitanti:= get_locate_abitanti_quartiere;
      arrived_tratto: tratto;
      residente: abitante;
      percorso: access route_and_distance;
   begin
      arrived_tratto:= resource_locate_abitanti.get_next(id_abitante);
      residente:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,id_abitante);
      -- get_id_quartiere coincide con residente.get_id_quartiere_from_abitante
      if residente.get_id_quartiere_from_abitante=arrived_tratto.get_id_quartiere_tratto and
        residente.get_id_luogo_casa_from_abitante=arrived_tratto.get_id_tratto then
         -- l'abitante si trova a casa
         -- lo si manda a lavorare
         percorso:= new route_and_distance'(get_server_gps.calcola_percorso(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto,residente.get_id_quartiere_luogo_lavoro_from_abitante,residente.get_id_luogo_lavoro_from_abitante));
      elsif residente.get_id_quartiere_luogo_lavoro_from_abitante=arrived_tratto.get_id_quartiere_tratto and
        residente.get_id_luogo_lavoro_from_abitante=arrived_tratto.get_id_tratto then
         -- l'abitante è a lavoro
         -- lo si manda a casa
         percorso:= new route_and_distance'(get_server_gps.calcola_percorso(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto,residente.get_id_quartiere_from_abitante,residente.get_id_luogo_casa_from_abitante));
         get_locate_abitanti_quartiere.set_percorso_abitante(residente.get_id_abitante_from_abitante,percorso.all);
      else  -- lo si manda a casa cmq
         percorso:= new route_and_distance'(get_server_gps.calcola_percorso(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto,residente.get_id_quartiere_from_abitante,residente.get_id_luogo_casa_from_abitante));
      end if;

      -- Invio richiesta ASINCRONA
      get_locate_abitanti_quartiere.set_percorso_abitante(residente.get_id_abitante_from_abitante,percorso.all);
      ptr_rt_ingresso(get_id_risorsa_quartiere(arrived_tratto.get_id_quartiere_tratto,arrived_tratto.get_id_tratto)).new_abitante_to_move(get_id_quartiere,id_abitante,car);

   end abitante_is_arrived;

   function get_quartiere_entities_life_obj return ptr_quartiere_entities_life is
   begin
      return quartiere_entities_life_obj;
   end get_quartiere_entities_life_obj;

   procedure start_entity_to_move is
      residente: abitante;
      percorso: access route_and_distance;
   begin
      Put_Line("avvia entità " & Positive'Image(get_from_abitanti) & " " & Positive'Image(get_to_abitanti));
      -- cicla su ogni abitante e invia richiesta all'ingresso

      --wait_settings_all_quartieri;

      for i in get_from_abitanti..get_to_abitanti loop
         residente:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,i);
         --calcola percorso e prendi il riferimento a locate del quartiere abitante e setta percorso
         Put_Line("request percorso");
         percorso:= new route_and_distance'(get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante, to_id_quartiere => residente.get_id_quartiere_luogo_lavoro_from_abitante, to_id_luogo => residente.get_id_luogo_lavoro_from_abitante));
         Put_Line("end request percorso");
         print_percorso(percorso.get_percorso_from_route_and_distance);
         get_locate_abitanti_quartiere.set_percorso_abitante(id_abitante => i, percorso => percorso.all);
         get_ingressi_segmento_resources(get_from_ingressi+residente.get_id_luogo_casa_from_abitante-1).new_abitante_to_move(residente.get_id_quartiere_from_abitante,residente.get_id_abitante_from_abitante,car);
      end loop;

   end start_entity_to_move;


end start_simulation;
