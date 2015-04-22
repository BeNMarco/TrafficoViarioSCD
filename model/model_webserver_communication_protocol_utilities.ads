with GNATCOLL.JSON;

with JSON_Helper;
with strade_e_incroci_common;
with numerical_types;

use GNATCOLL.JSON;

use JSON_Helper;
use strade_e_incroci_common;
use numerical_types;

package model_webserver_communication_protocol_utilities is

   -- where_ingresso è distance_from_road_head dell'urbana id_urbana
   function create_entità_traiettoria_ingresso_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: new_float; polo: Boolean; where_ingresso: Float; traiettoria: traiettoria_ingressi_type; mezzo: means_of_carrying) return JSON_Value;

   function create_car_traiettoria_cambio_corsia_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; begin_overtaken: Float; from_corsia: Positive; to_corsia: Positive) return JSON_Value;

   function create_entità_urbana_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; corsia: Positive; mezzo: means_of_carrying) return JSON_Value;

   function create_entità_ingresso_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_ingresso: Positive; id_ingresso: Positive; where: Float; polo: Boolean; mezzo: means_of_carrying) return JSON_Value;

   function create_entità_incrocio_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_incrocio: Positive; id_incrocio: Positive; where: Float; id_quartiere_urbana_ingresso: Natural; id_urbana_ingresso: Natural; direzione: traiettoria_incroci_type; mezzo: means_of_carrying) return JSON_Value;

   function create_semafori_colori_state(id_quartiere_incrocio: Positive; id_incrocio: Positive; verso_semafori_verdi: Boolean; bipedi_can_cross: Boolean) return JSON_Value;

   protected state_view_quartiere is
      procedure registra_aggiornamento_stato_risorsa(id_risorsa: Positive; stato_abitanti: JSON_Array; stato_semafori: JSON_Value; stato_abitanti_uscenti: JSON_Array);
   private
      num_task_updated: Natural:= 0;
      global_state_abitanti_quartiere: JSON_Array:= Empty_Array;
      global_state_semafori_quartiere: JSON_Array:= Empty_Array;
      global_state_abitanti_quartiere_uscenti: JSON_Array:= Empty_Array;
   end state_view_quartiere;


end model_webserver_communication_protocol_utilities;
