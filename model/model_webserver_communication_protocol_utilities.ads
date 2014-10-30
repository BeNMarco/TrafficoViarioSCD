with GNATCOLL.JSON;

with JSON_Helper;
with strade_e_incroci_common;

use GNATCOLL.JSON;

use JSON_Helper;
use strade_e_incroci_common;

package model_webserver_communication_protocol_utilities is

   -- where_ingresso è distance_from_road_head dell'urbana id_urbana
   function create_car_traiettoria_ingresso_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; where_ingresso: Float; traiettoria: traiettoria_ingressi_type) return JSON_Value;

   function create_car_traiettoria_cambio_corsia_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; begin_overtaken: Float; from_corsia: Positive; to_corsia: Positive) return JSON_Value;

   function create_car_urbana_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; corsia: Positive) return JSON_Value;

   function create_car_ingresso_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_ingresso: Positive; id_ingresso: Positive; where: Float; polo: Boolean) return JSON_Value;

   function create_car_incrocio_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_incrocio: Positive; id_incrocio: Positive; where: Float; id_quartiere_urbana_ingresso: Positive; id_urbana_ingresso: Positive; direzione: traiettoria_incroci_type) return JSON_Value;

   protected state_view_quartiere is
      procedure registra_aggiornamento_stato_risorsa(id_risorsa: Positive; stato: JSON_Array);
   private
      num_task_updated: Natural:= 0;
      global_state_quartiere: JSON_Array:= Empty_Array;
   end state_view_quartiere;


end model_webserver_communication_protocol_utilities;
