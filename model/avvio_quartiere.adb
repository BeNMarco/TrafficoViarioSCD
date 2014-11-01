with GNATCOLL.JSON;
with Ada.Text_IO;
with Polyorb.Parameters;
with Ada.Directories;
with Ada.Direct_IO;

with handle_semafori;
with JSON_Helper;
with strade_e_incroci_common;
with the_name_server;
with remote_types;
with resource_map_inventory;
with risorse_strade_e_incroci;
with start_simulation;
with data_quartiere;
with risorse_mappa_utilities;
with mailbox_risorse_attive;
with risorse_passive_data;
with snapshot_interface;

use GNATCOLL.JSON;
use Ada.Text_IO;

use JSON_Helper;
use strade_e_incroci_common;
use the_name_server;
use remote_types;
use resource_map_inventory;
use risorse_strade_e_incroci;
use start_simulation;
use data_quartiere;
use risorse_mappa_utilities;
use mailbox_risorse_attive;
use risorse_passive_data;
use snapshot_interface;

package body avvio_quartiere is

   procedure init is
   begin
      configure_quartiere_obj;
      configure_quartiere;

      declare
         File_Name: constant String:= "/home/marcobaesso/Scrivania/TrafficoViarioSCD/data/" & Polyorb.Parameters.Get_Conf("dsa","partition_name") & ".json";
         File_Size: Natural := Natural(Ada.Directories.Size(File_Name));

         subtype File_String    is String (1 .. File_Size);
         package File_String_IO is new Ada.Direct_IO (File_String);

         File: File_String_IO.File_Type;
         contents : File_String;
      begin
         File_String_IO.Open(File, Mode => File_String_IO.In_File, Name => File_Name);
         File_String_IO.Read(File, Item => contents);
         File_String_IO.Close(File);
         Put_Line("Registering quartiere " & Integer'Image(get_id_quartiere));
         --get_webServer.registra_mappa_quartiere(contents, get_id_quartiere);
      end;

      registra_quartiere_entities_life(get_id_quartiere,ptr_rt_quartiere_entities_life(get_quartiere_entities_life_obj));
      configure_tasks;
      start_entity_to_move;
   end init;

end avvio_quartiere;
