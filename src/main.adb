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
     create_array_urbane(json_roads => json_urbane, from => from_urbane, to => to_urbane);
   ingressi_features: strade_ingresso_features:=
     create_array_ingressi(json_roads => json_ingressi, from => from_ingressi, to => to_ingressi);

   json_incroci_a_4: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_4");
   json_incroci_a_3: JSON_Array:= Get(Val => json_quartiere, Field => "incroci_a_3");
   json_rotonde_a_4: JSON_Array:= Get(Val => json_quartiere, Field => "rotonde_a_4");
   json_rotonde_a_3: JSON_Array:= Get(Val => json_quartiere, Field => "rotonde_a_3");
   size_incroci_a_4: Natural:= Length(json_incroci_a_4);
   size_incroci_a_3: Natural:= Length(json_incroci_a_3);
   size_rotonde_a_4: Natural:= Length(json_rotonde_a_4);
   size_rotonde_a_3: Natural:= Length(json_rotonde_a_3);

   from_incroci_a_4: Natural:= 1;
   to_incroci_a_4: Natural:= size_incroci_a_4;
   from_incroci_a_3: Natural:= to_incroci_a_4+1;
   to_incroci_a_3: Natural:= from_incroci_a_3-1+size_incroci_a_3;
   from_rotonde_a_4: Natural:= to_incroci_a_3+1;
   to_rotonde_a_4: Natural:= from_rotonde_a_4-1+size_rotonde_a_4;
   from_rotonde_a_3: Natural:= to_rotonde_a_4+1;
   to_rotonde_a_3: Natural:= from_rotonde_a_3-1+size_rotonde_a_3;

   incroci_a_4: list_incroci_a_4(from_incroci_a_4..to_incroci_a_4):=
     create_array_incroci_a_4(json_incroci => json_incroci_a_4, from => from_incroci_a_4, to => to_incroci_a_4,
                              from_urbane => from_urbane, from_ingressi => from_ingressi);
   incroci_a_3: list_incroci_a_3(from_incroci_a_3..to_incroci_a_3):=
     create_array_incroci_a_3(json_incroci => json_incroci_a_3, from => from_incroci_a_3, to => to_incroci_a_3,
                              from_urbane => from_urbane, from_ingressi => from_ingressi);
   rotonde_a_4: list_incroci_a_4(from_rotonde_a_4..to_rotonde_a_4):=
     create_array_incroci_a_4(json_incroci => json_rotonde_a_4, from => from_rotonde_a_4, to => to_rotonde_a_4,
                              from_urbane => from_urbane, from_ingressi => from_ingressi);
   rotonde_a_3: list_incroci_a_3(from_rotonde_a_3..to_rotonde_a_3):=
     create_array_incroci_a_3(json_incroci => json_rotonde_a_3, from => from_rotonde_a_3, to => to_rotonde_a_3,
                              from_urbane => from_urbane, from_ingressi => from_ingressi);
   gps: ptr_gps_interface;
begin
   Put_Line(Integer'Image(size_rotonde_a_4));
   gps:= get_server_gps;
   gps.registra_urbane_quartiere(1, urbane_features);
   gps.registra_incroci_quartiere(1,incroci_a_4,incroci_a_3,rotonde_a_4,rotonde_a_3);
end main;
