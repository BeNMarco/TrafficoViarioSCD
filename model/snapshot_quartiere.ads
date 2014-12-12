with Ada.Text_IO;
with GNATCOLL.JSON;

with risorse_passive_data;

use Ada.Text_IO;
use GNATCOLL.JSON;

use risorse_passive_data;

package snapshot_quartiere is

   set_field_json_error: exception;

   protected snapshot_writer is
      procedure write_img_resource(img: JSON_Value; id_risorsa: Positive);
   private
      num_snap_resources: Natural:= 0;
      json_resources: JSON_Value;
      json_locate_abitanti: JSON_Value;
      json: JSON_Value;
      snap_file: File_Type;
   end snapshot_writer;

end snapshot_quartiere;
