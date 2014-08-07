with GNATCOLL.JSON;

with JSON_Helper;
with risorse_strade_e_incroci;
with strade_e_incroci_common;
use GNATCOLL.JSON;

use JSON_Helper;
use risorse_strade_e_incroci;
use strade_e_incroci_common;

package data_quartiere is

   function get_json_urbane return JSON_Array;
   function get_json_ingressi return JSON_Array;
   function get_json_incroci_a_4 return JSON_Array;
   function get_json_incroci_a_3 return JSON_Array;
   function get_json_rotonde_a_4 return JSON_Array;
   function get_json_rotonde_a_3 return JSON_Array;
   function get_from_urbane return Natural;
   function get_to_urbane return Natural;
   function get_from_ingressi return Natural;
   function get_to_ingressi return Natural;
   function get_from_incroci_a_4 return Natural;
   function get_to_incroci_a_4 return Natural;
   function get_from_incroci_a_3 return Natural;
   function get_to_incroci_a_3 return Natural;
   function get_from_rotonde_a_4 return Natural;
   function get_to_rotonde_a_4 return Natural;
   function get_from_rotonde_a_3 return Natural;
   function get_to_rotonde_a_3 return Natural;

private

   json_quartiere: JSON_Value:=Get_Json_Value(Json_String => "",Json_File_Name => "data/quartiere1.json");

   json_urbane: JSON_Array:= Get(Val => json_quartiere, Field => "strade");
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

   json_pedoni: JSON_Array:= Get(Val => json_quartiere, Field => "pedoni");
   json_bici: JSON_Array:= Get(Val => json_quartiere, Field => "bici");
   json_auto: JSON_Array:= Get(Val => json_quartiere, Field => "auto");
   json_abitanti: JSON_Array:= Get(Val => json_quartiere, Field => "abitanti");
   size_json_pedoni: Natural:= Length(json_pedoni);
   size_json_bici: Natural:= Length(json_bici);
   size_json_auto: Natural:= Length(json_auto);
   size_json_abitanti: Natural:= Length(json_abitanti);
   from_abitanti: Natural:= to_rotonde_a_3+1;
   to_abitanti: Natural:= from_abitanti+size_json_abitanti;


end data_quartiere;
