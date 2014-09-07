with mailbox_risorse_attive;
with resource_map_inventory;
with data_quartiere;
with strade_e_incroci_common;
with the_name_server;
with remote_types;

use mailbox_risorse_attive;
use resource_map_inventory;
use data_quartiere;
use strade_e_incroci_common;
use the_name_server;
use remote_types;

package body start_simulation is

   protected body quartiere_entities_life is
      procedure abitante_is_arrived(id_quartiere: Positive; id_abitante: Positive) is
      begin
         null;
      end abitante_is_arrived;
      procedure start_entity_to_move is
         residente: abitante;
         resource_segmento: ptr_rt_segmento;
      begin
         -- cicla su ogni abitante e invia richiesta all'ingresso ASINCRONA
         for i in get_from_abitanti..get_to_abitanti loop
            residente:= get_quartiere_utilities_obj.get_abitante_quartiere(get_id_quartiere,i);
            resource_segmento:= get_id_risorsa_quartiere(residente.get_id_quartiere_from_abitante,residente.get_id_luogo_casa_from_abitante);
            --calcola percorso e prendi il riferimento a locate del quartiere abitante e setta percorso
            get_locate_abitanti_quartiere.set_percorso_abitante(id_abitante => i, percorso => get_server_gps.calcola_percorso(from_id_quartiere => residente.get_id_quartiere_from_abitante, from_id_luogo => residente.get_id_luogo_casa_from_abitante, to_id_quartiere => residente.get_id_quartiere_luogo_lavoro_from_abitante, to_id_luogo => residente.get_id_luogo_lavoro_from_abitante));
            --get_ingressi_segmento_resources(residente.get_id_luogo_casa_from_abitante).registra_abitante_to_move(road,);
         end loop;
      end start_entity_to_move;

   end quartiere_entities_life;

end start_simulation;
