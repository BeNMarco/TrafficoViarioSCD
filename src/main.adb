with GNATCOLL.JSON;
with Ada.Text_IO;

with JSON_Helper;
with strade_common;
with strade_common.strade_features;
with name_server_utilities;
with partition_setup_utilities;

use GNATCOLL.JSON;
use Ada.Text_IO;

use name_server_utilities;
use JSON_Helper;
use strade_common;
use name_server_utilities;
use partition_setup_utilities;
use strade_common.strade_features;

procedure main is
   json_quartiere: JSON_Value:=Get_Json_Value(Json_String => "",Json_File_Name => "data/quartiere1.json");
   urbane_features: strade_urbane_features:= create_array_strade(json_roads => Get(Val => json_quartiere, Field => "strade"));
   ingressi_features: strade_ingresso_features:= create_array_ingressi(json_roads => Get(Val => json_quartiere, Field => "strade_ingresso"));
   json_incroci_a_4: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_4");
   json_incroci_a_3: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_3");
   json_incroci_a_2: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_2");
   size_incroci_a_4: Natural:= Length(json_incroci_a_4);
   size_incroci_a_3: Natural:= Length(json_incroci_a_3);
   size_incroci_a_2: Natural:= Length(json_incroci_a_2);

   from_incroci_a_4: Positive:= 1;
   to_incroci_a_4: Positive:= size_incroci_a_4;
   from_incroci_a_3: Positive:= size_incroci_a_4+1;
   to_incroci_a_3: Positive:= size_incroci_a_4+size_incroci_a_3;
   from_incroci_a_2: Positive:= size_incroci_a_4+size_incroci_a_3+1;
   to_incroci_a_2: Positive:= size_incroci_a_2+size_incroci_a_4+size_incroci_a_3;

   incroci_a_4: list_incroci_a_4(from_incroci_a_4..size_incroci_a_4):=
     create_array_incroci_a_4(json_incroci => json_incroci_a_4, from => from_incroci_a_4, to => to_incroci_a_4);
   incroci_a_3: list_incroci_a_3(from_incroci_a_3..to_incroci_a_3):=
     create_array_incroci_a_3(json_incroci => json_incroci_a_3, from => from_incroci_a_3, to => to_incroci_a_3);
   incroci_a_2: list_incroci_a_2(from_incroci_a_2..to_incroci_a_2):=
     create_array_incroci_a_2(json_incroci => json_incroci_a_2, from => from_incroci_a_2, to => to_incroci_a_2);
begin
   null;
end main;
