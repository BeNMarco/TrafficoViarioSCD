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
   ptr_array_strade: ptr_strade_urbane_features:= create_array_strade(json_roads => Get(Val => json_quartiere, Field => "strade"));

begin
   null;
end main;
