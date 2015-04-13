with GNATCOLL.JSON;
with Ada.Text_IO;

with JSON_Helper;
with strade_e_incroci_common;
with data_quartiere;
with the_name_server;
with remote_types;
with global_data;

use GNATCOLL.JSON;
use Ada.Text_IO;

use JSON_Helper;
use strade_e_incroci_common;
use data_quartiere;
use the_name_server;
use remote_types;
use global_data;

package body model_webserver_communication_protocol_utilities is

   function create_entità_traiettoria_ingresso_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; where_ingresso: Float; traiettoria: traiettoria_ingressi_type; mezzo: means_of_carrying) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","traiettoria_ingresso");
      json.Set_Field("id_quartiere_where",id_quartiere_urbana);
      json.Set_Field("id_where",id_urbana);
      json.Set_Field("distanza",where);
      json.Set_Field("polo",polo);
      json.Set_Field("distanza_ingresso",where_ingresso);
      json.Set_Field("traiettoria",to_string_ingressi_type(traiettoria));
      json.Set_Field("mezzo",convert_means_to_string(mezzo));
      return json;
   end create_entità_traiettoria_ingresso_state;

   function create_car_traiettoria_cambio_corsia_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; begin_overtaken: Float; from_corsia: Positive; to_corsia: Positive) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","cambio_corsia");
      json.Set_Field("id_quartiere_where",id_quartiere_urbana);
      json.Set_Field("id_where",id_urbana);
      json.Set_Field("distanza",where);
      json.Set_Field("polo",polo);
      json.Set_Field("distanza_inizio",begin_overtaken);
      json.Set_Field("corsia_inizio",from_corsia);
      json.Set_Field("corsia_fine",to_corsia);
      json.Set_Field("mezzo","car");
      return json;
   end create_car_traiettoria_cambio_corsia_state;

   function create_entità_urbana_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; corsia: Positive; mezzo: means_of_carrying) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","strada");
      json.Set_Field("id_quartiere_where",id_quartiere_urbana);
      json.Set_Field("id_where",id_urbana);
      json.Set_Field("distanza",where);
      json.Set_Field("polo",polo);
      json.Set_Field("corsia",corsia);
      json.Set_Field("mezzo",convert_means_to_string(mezzo));
      return json;
   end create_entità_urbana_state;

   function create_entità_ingresso_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_ingresso: Positive; id_ingresso: Positive; where: Float; polo: Boolean; mezzo: means_of_carrying) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","strada_ingresso");
      json.Set_Field("id_quartiere_where",id_quartiere_ingresso);
      json.Set_Field("id_where",id_ingresso);
      json.Set_Field("distanza",where);
      json.Set_Field("in_uscita",polo);
      case mezzo is
         when car =>
            json.Set_Field("corsia",1);
         when bike =>
            json.Set_Field("corsia",1);
         when walking =>
            json.Set_Field("corsia",2);
      end case;
      json.Set_Field("mezzo",convert_means_to_string(mezzo));
      return json;
   end create_entità_ingresso_state;

   function create_entità_incrocio_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_incrocio: Positive; id_incrocio: Positive; where: Float; id_quartiere_urbana_ingresso: Natural; id_urbana_ingresso: Natural; direzione: traiettoria_incroci_type; mezzo: means_of_carrying) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","incrocio");
      json.Set_Field("id_quartiere_where",id_quartiere_incrocio);
      json.Set_Field("id_where",id_incrocio);
      json.Set_Field("distanza",where);
      json.Set_Field("quartiere_strada_ingresso",id_quartiere_urbana_ingresso);
      json.Set_Field("strada_ingresso",id_urbana_ingresso);
      json.Set_Field("direzione",to_string_incroci_type(direzione));
      json.Set_Field("mezzo",convert_means_to_string(mezzo));
      return json;
   end create_entità_incrocio_state;

   protected body state_view_quartiere is
      procedure registra_aggiornamento_stato_risorsa(id_risorsa: Positive; stato: JSON_Array) is
         json: JSON_Value;
      begin
         if get_abilita_aggiornamenti_view then
            num_task_updated:= num_task_updated+1;
            for i in 1..Length(stato) loop
               Append(global_state_quartiere,Get(stato,i));
            end loop;
            if num_task_updated=get_num_task then
               num_task_updated:= 0;
               json:= Create_Object;
               json.Set_Field("entità",global_state_quartiere);
               get_webServer.invia_aggiornamento(Write(json),get_id_quartiere);
               global_state_quartiere:= Empty_Array;
            end if;
         end if;
      end registra_aggiornamento_stato_risorsa;
   end state_view_quartiere;

end model_webserver_communication_protocol_utilities;
