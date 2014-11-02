with GNATCOLL.JSON;
with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Polyorb.Parameters;

with JSON_Helper;
with strade_e_incroci_common;
with the_name_server;

use GNATCOLL.JSON;
use Ada.Directories;
use Ada.Text_IO;
use Ada.Strings.Unbounded;

use JSON_Helper;
use strade_e_incroci_common;
use the_name_server;

with absolute_path;
use absolute_path;

package data_quartiere is
pragma Elaborate_Body;
   function get_id_quartiere return Positive;
   function get_name_quartiere return String;
   function get_json_urbane return JSON_Array;
   function get_json_quartiere return JSON_Value;
   function get_json_ingressi return JSON_Array;
   function get_json_incroci_a_4 return JSON_Array;
   function get_json_incroci_a_3 return JSON_Array;
   function get_json_rotonde_a_4 return JSON_Array;
   function get_json_rotonde_a_3 return JSON_Array;
   function get_json_traiettorie_incrocio return JSON_Value;
   function get_json_traiettorie_ingresso return JSON_Value;
   function get_json_traiettorie_cambio_corsie return JSON_Value;
   function get_json_road_parameters return JSON_Value;
   function get_from_urbane return Natural;
   function get_to_urbane return Natural;
   function get_from_ingressi return Natural;
   function get_to_ingressi return Natural;
   function get_from_incroci_a_4 return Natural;
   function get_to_incroci_a_4 return Natural;
   function get_from_incroci_a_3 return Natural;
   function get_to_incroci_a_3 return Natural;
   function get_from_incroci return Natural;
   function get_to_incroci return Natural;
   function get_from_rotonde_a_4 return Natural;
   function get_to_rotonde_a_4 return Natural;
   function get_from_rotonde_a_3 return Natural;
   function get_to_rotonde_a_3 return Natural;
   function get_json_pedoni return JSON_Array;
   function get_json_bici return JSON_Array;
   function get_json_auto return JSON_Array;
   function get_json_abitanti return JSON_Array;
   function get_from_abitanti return Natural;
   function get_to_abitanti return Natural;
   function get_default_value_pedoni(value: move_settings) return Float;
   function get_default_value_bici(value: move_settings) return Float;
   function get_default_value_auto(value: move_settings) return Float;
   function get_num_abitanti return Natural;
   function get_num_task return Natural;
   function get_recovery return Boolean;

private

   name_quartiere: String:= Polyorb.Parameters.Get_Conf("dsa","partition_name");

   json_quartiere: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/" & name_quartiere & ".json");
   json_traiettorie_incroci: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/traiettorie_incroci.json");
   json_traiettorie_ingressi: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/traiettorie_ingressi.json");

   id_quartiere: Positive:= Get(Val => json_quartiere, Field => "id_quartiere");

   json_urbane: JSON_Array:= Get(Val => json_quartiere, Field => "strade_urbane");
   json_ingressi: JSON_Array:= Get(Val => json_quartiere, Field => "strade_ingresso");
   size_json_urbane: Natural:= Length(json_urbane);
   size_json_ingressi: Natural:= Length(json_ingressi);
   from_urbane: Natural:= 1;
   to_urbane: Natural:= size_json_urbane;
   from_ingressi: Natural:= size_json_urbane+1;
   to_ingressi: Natural:= size_json_ingressi+size_json_urbane;

   json_incroci_a_4: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_4");
   json_incroci_a_3: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_3");
   json_rotonde_a_4: JSON_Array:= Get(Val => json_quartiere, Field => "rotonde_a_4");
   json_rotonde_a_3: JSON_Array:= Get(Val => json_quartiere, Field => "rotonde_a_3");
   size_incroci_a_4: Natural:= Length(json_incroci_a_4);
   size_incroci_a_3: Natural:= Length(json_incroci_a_3);
   size_rotonde_a_4: Natural:= Length(json_rotonde_a_4);
   size_rotonde_a_3: Natural:= Length(json_rotonde_a_3);
   from_incroci_a_4: Natural:= to_ingressi+1;
   to_incroci_a_4: Natural:= from_incroci_a_4-1+size_incroci_a_4;
   from_incroci_a_3: Natural:= to_incroci_a_4+1;
   to_incroci_a_3: Natural:= from_incroci_a_3-1+size_incroci_a_3;
   from_rotonde_a_4: Natural:= to_incroci_a_3+1;
   to_rotonde_a_4: Natural:= from_rotonde_a_4-1+size_rotonde_a_4;
   from_rotonde_a_3: Natural:= to_rotonde_a_4+1;
   to_rotonde_a_3: Natural:= from_rotonde_a_3-1+size_rotonde_a_3;

   num_task: Natural:= size_json_urbane+size_json_ingressi+size_incroci_a_4+size_incroci_a_3+size_rotonde_a_4+size_rotonde_a_3;

   json_abitanti: JSON_Array:= Get(Val => json_quartiere, Field => "abitanti");
   json_pedoni: JSON_Array:= Get(Val => json_quartiere, Field => "pedoni");
   json_bici: JSON_Array:= Get(Val => json_quartiere, Field => "bici");
   json_auto: JSON_Array:= Get(Val => json_quartiere, Field => "auto");
   size_json_abitanti: Natural:= Length(json_abitanti);
   size_json_pedoni: Natural:= Length(json_pedoni);
   size_json_bici: Natural:= Length(json_bici);
   size_json_auto: Natural:= Length(json_auto);
   from_abitanti: Natural:= to_rotonde_a_3+1;
   to_abitanti: Natural:= from_abitanti-1+size_json_abitanti;

   -- BEGIN VALORI DI DEFAULT PER RISORSE PASSIVE
   default_desired_velocity_pedoni: Float:= Get(Val => json_quartiere, Field => "default_pedoni").Get("desired_velocity");
   default_time_headway_pedoni: Float:= Get(Val => json_quartiere, Field => "default_pedoni").Get("time_headway");
   default_max_acceleration_pedoni: Float:= Get(Val => json_quartiere, Field => "default_pedoni").Get("max_acceleration");
   default_comfortable_deceleration_pedoni: Float:= Get(Val => json_quartiere, Field => "default_pedoni").Get("comfortable_deceleration");
   default_s0_pedoni: Float:= Get(Val => json_quartiere, Field => "default_pedoni").Get("s0");
   default_length_pedoni: Float:= Get(Val => json_quartiere, Field => "default_pedoni").Get("length");

   default_desired_velocity_bici: Float:= Get(Val => json_quartiere, Field => "default_bici").Get("desired_velocity");
   default_time_headway_bici: Float:= Get(Val => json_quartiere, Field => "default_bici").Get("time_headway");
   default_max_acceleration_bici: Float:= Get(Val => json_quartiere, Field => "default_bici").Get("max_acceleration");
   default_comfortable_deceleration_bici: Float:= Get(Val => json_quartiere, Field => "default_bici").Get("comfortable_deceleration");
   default_s0_bici: Float:= Get(Val => json_quartiere, Field => "default_bici").Get("s0");
   default_length_bici: Float:= Get(Val => json_quartiere, Field => "default_bici").Get("length");

   default_desired_velocity_auto: Float:= Get(Val => json_quartiere, Field => "default_auto").Get("desired_velocity");
   default_time_headway_auto: Float:= Get(Val => json_quartiere, Field => "default_auto").Get("time_headway");
   default_max_acceleration_auto: Float:= Get(Val => json_quartiere, Field => "default_auto").Get("max_acceleration");
   default_comfortable_deceleration_auto: Float:= Get(Val => json_quartiere, Field => "default_auto").Get("comfortable_deceleration");
   default_s0_auto: Float:= Get(Val => json_quartiere, Field => "default_auto").Get("s0");
   default_length_auto: Float:= Get(Val => json_quartiere, Field => "default_auto").Get("length");
   default_num_posti_auto: Positive:= Get(Val => json_quartiere, Field => "default_auto").Get("num_posti");

   json_traiettorie_incrocio: JSON_Value:= Get(Val => json_traiettorie_incroci, Field => "traiettorie_incrocio");
   json_traiettorie_ingresso: JSON_Value:= Get(Val => json_traiettorie_ingressi, Field => "traiettorie_ingresso");
   json_traiettorie_cambio_corsie: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/traiettorie_cambio_corsia.json");
   json_road_parameters: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/road_parameters.json");
   -- END VALORI DI DEFAULT PER RISORSE PASSIVE

   json_recovery: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/snapshot/recovery.json");
   recovery: Boolean:= json_recovery.Get("abilita_ripristino");


end data_quartiere;
