with GNATCOLL.JSON;
with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Polyorb.Parameters;

with JSON_Helper;
with strade_e_incroci_common;
with the_name_server;
with remote_types;

use GNATCOLL.JSON;
use Ada.Directories;
use Ada.Text_IO;
use Ada.Strings.Unbounded;

use JSON_Helper;
use strade_e_incroci_common;
use the_name_server;
use remote_types;

with absolute_path;
use absolute_path;

with numerical_types;
use numerical_types;

package data_quartiere is
pragma Elaborate_Body;
   function get_id_quartiere return Positive;
   function get_name_quartiere return String;
   function get_json_urbane return JSON_Array;
   function get_json_quartiere return JSON_Value;
   function get_json_default_movement_entity return JSON_Value;
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
   --function get_from_rotonde_a_4 return Natural;
   --function get_to_rotonde_a_4 return Natural;
   --function get_from_rotonde_a_3 return Natural;
   --function get_to_rotonde_a_3 return Natural;
   function get_json_pedoni return JSON_Array;
   function get_json_bici return JSON_Array;
   function get_json_auto return JSON_Array;
   function get_json_abitanti return JSON_Array;
   function get_json_autobus return JSON_Array;
   function get_json_fermate_autobus return JSON_Array;
   function get_json_abitanti_in_bus return JSON_Array;
   function get_json_luoghi return JSON_Array;
   function get_from_abitanti return Natural;
   function get_to_abitanti return Natural;
   function get_num_abitanti return Natural;
   function get_num_autobus return Natural;
   function get_num_task return Natural;
   function get_num_linee_fermate return Natural;
   function get_recovery return Boolean;
   function get_abilita_aggiornamenti_view return Boolean;


   protected type report_log is new rt_report_log with
        procedure configure;
         procedure finish(id_quartiere: Positive);
      --procedure write(stringa: String);
      procedure write_state_stallo(id_quartiere: Positive; id_abitante: Positive; reset: Boolean);
   private
      OutFile: File_Type;
   end report_log;

   type ptr_report_log is access all report_log;

   function get_log_stallo_quartiere return ptr_report_log;

private

   name_quartiere: String:= Polyorb.Parameters.Get_Conf("dsa","partition_name");

   json_quartiere: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/" & name_quartiere & ".json");
   json_traiettorie_incroci: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/traiettorie_incroci.json");
   json_traiettorie_ingressi: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/traiettorie_ingressi.json");
   json_aggiornamenti: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/abilita_invio_aggiornamenti.json");

   abilita_aggiornamenti_view: Boolean:= Get(Val => json_aggiornamenti, Field => "abilita_invio_aggiornamenti");

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
   --from_rotonde_a_4: Natural:= to_incroci_a_3+1;
   --to_rotonde_a_4: Natural:= from_rotonde_a_4-1+size_rotonde_a_4;
   --from_rotonde_a_3: Natural:= to_rotonde_a_4+1;
   --to_rotonde_a_3: Natural:= from_rotonde_a_3-1+size_rotonde_a_3;

   num_task: Natural:= size_json_urbane+size_json_ingressi+size_incroci_a_4+size_incroci_a_3+size_rotonde_a_4+size_rotonde_a_3;

   json_abitanti: JSON_Array:= Get(Val => json_quartiere, Field => "abitanti");
   json_pedoni: JSON_Array:= Get(Val => json_quartiere, Field => "pedoni");
   json_bici: JSON_Array:= Get(Val => json_quartiere, Field => "bici");
   json_auto: JSON_Array:= Get(Val => json_quartiere, Field => "auto");
   json_autobus: JSON_Array:= Get(Val => json_quartiere, Field => "autobus");
   size_json_abitanti: Natural:= Length(json_abitanti);
   size_json_pedoni: Natural:= Length(json_pedoni);
   size_json_bici: Natural:= Length(json_bici);
   size_json_auto: Natural:= Length(json_auto);
   size_json_autobus: Natural:= Length(json_autobus);
   from_abitanti: Natural:= to_incroci_a_3+1;
   to_abitanti: Natural:= from_abitanti-1+size_json_abitanti+size_json_autobus;

   json_default_move_settings: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/default_move_settings.json");

   json_traiettorie_incrocio: JSON_Value:= Get(Val => json_traiettorie_incroci, Field => "traiettorie_incrocio");
   json_traiettorie_ingresso: JSON_Value:= Get(Val => json_traiettorie_ingressi, Field => "traiettorie_ingresso");
   json_traiettorie_cambio_corsie: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/traiettorie_cambio_corsia.json");
   json_road_parameters: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/road_parameters.json");

   json_luoghi: JSON_Array:= Get(Val => json_quartiere, Field => "luoghi");

   json_fermate_autobus: JSON_Array:= Get(Val => json_quartiere, Field => "fermate_autobus");
   num_linee_fermate: Natural:= Length(json_fermate_autobus);
   json_recovery: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/snapshot/recovery.json");
   recovery: Boolean:= json_recovery.Get("abilita_ripristino");

   json_abitanti_in_bus: JSON_Array:= Get(Val => json_quartiere, Field => "abitanti_in_bus");

   my_log_stallo: ptr_report_log:= new report_log;

end data_quartiere;
