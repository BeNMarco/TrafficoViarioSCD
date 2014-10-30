with Ada.Text_IO;
with GNATCOLL.JSON;

with risorse_passive_data;

use Ada.Text_IO;
use GNATCOLL.JSON;

use risorse_passive_data;

package snapshot_quartiere is

   protected snapshot_writer is
      procedure write_img_resource(img: JSON_Value; id_risorsa: Positive);
   private
      num_snap_resources: Natural:= 0;
      json_resources: JSON_Value:= Create;
      json_locate_abitanti: JSON_Value:= Create;
      json: JSON_Value:= Create;
      snap_file: File_Type;
   end snapshot_writer;

end snapshot_quartiere;
