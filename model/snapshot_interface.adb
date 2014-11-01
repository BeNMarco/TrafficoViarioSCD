with GNATCOLL.JSON;
with Ada.Text_IO;

with JSON_Helper;
with absolute_path;
with data_quartiere;

use GNATCOLL.JSON;
use Ada.Text_IO;

use JSON_Helper;
use absolute_path;
use data_quartiere;

package body snapshot_interface is

   protected body share_snapshot_file_quartiere is

      procedure get_json_value_resource_snap(id_risorsa: Positive; json_resource: out JSON_Value) is
      begin
         json_resource:= json_snap.Get("risorse").Get(Positive'Image(id_risorsa));
      end get_json_value_resource_snap;

      procedure get_json_value_locate_abitanti(json_locate: out JSON_Value) is
      begin
         json_locate:= json_snap.Get("locate_abitanti");
      end get_json_value_locate_abitanti;

      procedure configure is
         snap_file: File_Type;
      begin
         json_snap:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/snapshot/" & get_name_quartiere & "_snapshot.json");
      end configure;

   end share_snapshot_file_quartiere;
begin
   share_snapshot_file_quartiere.configure;
end snapshot_interface;
