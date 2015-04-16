with GNATCOLL.JSON;
with Ada.Text_IO;

with JSON_Helper;
with strade_e_incroci_common;
with data_quartiere;
with the_name_server;
with remote_types;
with global_data;
with risorse_passive_data;

use GNATCOLL.JSON;
use Ada.Text_IO;

use JSON_Helper;
use strade_e_incroci_common;
use data_quartiere;
use the_name_server;
use remote_types;
use global_data;
use risorse_passive_data;

package body model_webserver_communication_protocol_utilities is

   procedure set_length_parameters_abitante(json: in out JSON_Value; mezzo: means_of_carrying; id_quartiere_abitante: Positive; id_abitante: Positive) is
   begin
      json.Set_Field("is_a_bus",get_quartiere_utilities_obj.get_abitante_quartiere(id_quartiere_abitante,id_abitante).is_a_bus);
      case mezzo is
         when car =>
            json.Set_Field("length_abitante",Float(get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_abitante,id_abitante).get_length_entità_passiva));
         when bike =>
            json.Set_Field("length_abitante",Float(get_quartiere_utilities_obj.get_bici_quartiere(id_quartiere_abitante,id_abitante).get_length_entità_passiva));
         when walking =>
            json.Set_Field("length_abitante",Float(get_quartiere_utilities_obj.get_pedone_quartiere(id_quartiere_abitante,id_abitante).get_length_entità_passiva));
      end case;
   end set_length_parameters_abitante;

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

      set_length_parameters_abitante(json,mezzo,id_quartiere_abitante,id_abitante);

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

      set_length_parameters_abitante(json,car,id_quartiere_abitante,id_abitante);

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

      set_length_parameters_abitante(json,mezzo,id_quartiere_abitante,id_abitante);

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

      set_length_parameters_abitante(json,mezzo,id_quartiere_abitante,id_abitante);

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

      set_length_parameters_abitante(json,mezzo,id_quartiere_abitante,id_abitante);

      return json;
   end create_entità_incrocio_state;

   function create_semafori_colori_state(id_quartiere_incrocio: Positive; id_incrocio: Positive; verso_semafori_verdi: Boolean; bipedi_can_cross: Boolean) return JSON_Value is
      json: JSON_Value:= Create_Object;
      json_arr_1: JSON_Array:= Empty_Array;
      json_arr_2: JSON_Array:= Empty_Array;
   begin
      json.Set_Field("id_quartiere_incrocio",id_quartiere_incrocio);
      json.Set_Field("id_incrocio",id_incrocio);
      json.Set_Field("abilitato_pedoni_bici",bipedi_can_cross);
      if bipedi_can_cross then
         Append(json_arr_1,Create(0));
         Append(json_arr_1,Create(1));
         Append(json_arr_1,Create(2));
         Append(json_arr_1,Create(3));
         json.Set_Field("index_road_rossi",json_arr_1);
         json.Set_Field("index_road_verdi",json_arr_2);
      else
         if verso_semafori_verdi then
            -- True => 1 e 3 verdi
            -- False => 2 e 4 verdi
            Append(json_arr_1,Create(1));
            Append(json_arr_1,Create(3));
            json.Set_Field("index_road_rossi",json_arr_1);
            Append(json_arr_2,Create(0));
            Append(json_arr_2,Create(2));
            json.Set_Field("index_road_verdi",json_arr_2);
         else
            Append(json_arr_1,Create(0));
            Append(json_arr_1,Create(2));
            json.Set_Field("index_road_rossi",json_arr_1);
            Append(json_arr_2,Create(1));
            Append(json_arr_2,Create(3));
            json.Set_Field("index_road_verdi",json_arr_2);
         end if;
      end if;
      return json;
   end create_semafori_colori_state;

   protected body state_view_quartiere is
      procedure registra_aggiornamento_stato_risorsa(id_risorsa: Positive; stato_abitanti: JSON_Array; stato_semafori: JSON_Value; stato_abitanti_uscenti: JSON_Array) is
         json: JSON_Value;
      begin
         if get_abilita_aggiornamenti_view then
            num_task_updated:= num_task_updated+1;
            for i in 1..Length(stato_abitanti) loop
               Append(global_state_abitanti_quartiere,Get(stato_abitanti,i));
            end loop;
            Append(global_state_semafori_quartiere,stato_semafori);
            for i in 1..Length(stato_abitanti_uscenti) loop
               Append(global_state_abitanti_quartiere_uscenti,Get(stato_abitanti_uscenti,i));
            end loop;
            if num_task_updated=get_num_task then
               num_task_updated:= 0;
               json:= Create_Object;
               json.Set_Field("abitanti",global_state_abitanti_quartiere);
               json.Set_Field("semafori",global_state_semafori_quartiere);
               json.Set_Field("abitanti_uscenti",global_state_abitanti_quartiere_uscenti);
               get_webServer.invia_aggiornamento(Write(json),get_id_quartiere);
               global_state_abitanti_quartiere:= Empty_Array;
               global_state_semafori_quartiere:= Empty_Array;
               global_state_abitanti_quartiere_uscenti:= Empty_Array;
            end if;
         end if;
      end registra_aggiornamento_stato_risorsa;
   end state_view_quartiere;

end model_webserver_communication_protocol_utilities;
