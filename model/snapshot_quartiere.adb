with Ada.Text_IO;
with GNATCOLL.JSON;
with Polyorb.Parameters;

with risorse_passive_data;
with data_quartiere;
with absolute_path;

use Ada.Text_IO;
use GNATCOLL.JSON;
use Polyorb.Parameters;

use risorse_passive_data;
use data_quartiere;
use absolute_path;

package body snapshot_quartiere is

   protected body snapshot_writer is

      procedure write_img_resource(img: JSON_Value; id_risorsa: Positive) is
      begin
         begin
         num_snap_resources:= num_snap_resources+1;
         -- creo l'oggetto se necessario
         if num_snap_resources=1 then
            json:= Create_Object;
            json_resources:= Create_Object;
         end if;
         -- creo lo snapshot del locate abitanti
         json_resources.Set_Field(Positive'Image(id_risorsa),img);

         if num_snap_resources=get_num_task then
            num_snap_resources:= 0;
            json.Set_Field("risorse",json_resources);
            json_locate_abitanti:= Create_Object;
            get_locate_abitanti_quartiere.create_img(json_locate_abitanti);
            json.Set_Field("locate_abitanti",json_locate_abitanti);
            Open(File => snap_file, Name => abs_path & "data/snapshot/" & Polyorb.Parameters.Get_Conf("dsa","partition_name") & "_snapshot.json", Mode => Out_File);
            Put_Line(snap_file, Write(json,False));
            Close(snap_file);
         end if;
         exception
            when others =>
               Put_Line("ERROR in Write " & Positive'Image(get_id_quartiere));
               raise set_field_json_error;
         end;
      end write_img_resource;

   end snapshot_writer;

end snapshot_quartiere;
