with GNATCOLL.JSON;
with Ada.Text_IO;
with Polyorb.Parameters;
with Ada.Directories;
with Ada.Direct_IO;

with absolute_path;
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

use absolute_path;
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
      json_quartiere: JSON_Value:= get_json_quartiere;
      array_elementi: JSON_Array;
      elemento: JSON_Value;
   begin
      configure_quartiere_obj;
      configure_quartiere;

      array_elementi:= json_quartiere.Get("strade_ingresso");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id",get_from_ingressi+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("incroci_a_4");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id",get_from_incroci_a_4+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("incroci_a_3");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id",get_from_incroci_a_3+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("luoghi");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_luogo",get_from_ingressi+i-1);
         elemento.Set_Field("idstrada",get_from_ingressi+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("pedoni");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_abitante",get_from_abitanti+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("auto");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_abitante",get_from_abitanti+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("bici");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_abitante",get_from_abitanti+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("abitanti");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_abitante",get_from_abitanti+i-1);
      end loop;

      get_webServer.registra_mappa_quartiere(Write(json_quartiere,False), get_id_quartiere);
      --Put_Line("Registrato quartiere " & Integer'Image(get_id_quartiere));

      registra_quartiere_entities_life(get_id_quartiere,ptr_rt_quartiere_entities_life(get_quartiere_entities_life_obj));
      configure_tasks;
      start_entity_to_move;
   end init;

end avvio_quartiere;
