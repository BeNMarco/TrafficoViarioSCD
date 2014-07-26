with GNATCOLL.JSON;
with Ada.Text_IO;

with JSON_Helper;
with strade_e_incroci_common;
with partition_setup_utilities;
with the_name_server;
with remote_types;

use GNATCOLL.JSON;
use Ada.Text_IO;

use JSON_Helper;
use strade_e_incroci_common;
use partition_setup_utilities;
use the_name_server;
use remote_types;

procedure main is
   json_quartiere: JSON_Value:=Get_Json_Value(Json_String => "",Json_File_Name => "data/quartiere1.json");

   json_urbane: JSON_Array:= Get(Val => json_quartiere, Field => "strade");
   json_ingressi: JSON_Array:= Get(Val => json_quartiere, Field => "strade_ingresso");
   size_json_urbane: Positive:= Length(json_urbane);
   size_json_ingressi: Positive:= Length(json_ingressi);

   from_urbane: Positive:= 1;
   to_urbane: Positive:= size_json_urbane;
   from_ingressi: Positive:= size_json_urbane+1;
   to_ingressi: Positive:= size_json_ingressi+size_json_urbane;

   urbane_features: strade_urbane_features:=
     create_array_strade(json_roads => json_urbane, from => from_urbane, to => to_urbane);
   ingressi_features: strade_ingresso_features:=
     create_array_ingressi(json_roads => json_ingressi, from => from_ingressi, to => to_ingressi);

   json_incroci_a_4: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_4");
   json_incroci_a_3: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_3");
   --json_incroci_a_2: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_2");
   size_incroci_a_4: Natural:= Length(json_incroci_a_4);
   size_incroci_a_3: Natural:= Length(json_incroci_a_3);
   --size_incroci_a_2: Natural:= Length(json_incroci_a_2);

   from_incroci_a_4: Positive:= 1;
   to_incroci_a_4: Positive:= size_incroci_a_4;
   from_incroci_a_3: Positive:= size_incroci_a_4+1;
   to_incroci_a_3: Positive:= size_incroci_a_4+size_incroci_a_3;
   --from_incroci_a_2: Positive:= size_incroci_a_4+size_incroci_a_3+1;
   --to_incroci_a_2: Positive:= size_incroci_a_2+size_incroci_a_4+size_incroci_a_3;

   incroci_a_4: list_incroci_a_4(from_incroci_a_4..size_incroci_a_4):=
     create_array_incroci_a_4(json_incroci => json_incroci_a_4, from => from_incroci_a_4, to => to_incroci_a_4,
                              from_urbane => from_urbane, from_ingressi => from_ingressi);
   incroci_a_3: list_incroci_a_3(from_incroci_a_3..to_incroci_a_3):=
     create_array_incroci_a_3(json_incroci => json_incroci_a_3, from => from_incroci_a_3, to => to_incroci_a_3,
                              from_urbane => from_urbane, from_ingressi => from_ingressi);
   --incroci_a_2: list_incroci_a_2(from_incroci_a_2..to_incroci_a_2):=
    -- create_array_incroci_a_2(json_incroci => json_incroci_a_2, from => from_incroci_a_2, to => to_incroci_a_2,
      --                        from_urbane => from_urbane, from_ingressi => from_ingressi);
   gps: ptr_gps_interface;
begin
   gps:= get_server_gps;
   gps.registra_urbane_quartiere(1, urbane_features);
end main;
