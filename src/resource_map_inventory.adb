with ada.Text_IO;

with global_data;
with remote_types;
with the_name_server;
with risorse_passive_utilities;
with configuration_synchronized_package;
with mailbox_risorse_attive;
with handle_semafori;
with risorse_passive_data;

use Ada.Text_IO;

use global_data;
use remote_types;
use the_name_server;
use risorse_passive_utilities;
use configuration_synchronized_package;
use mailbox_risorse_attive;
use handle_semafori;
use risorse_passive_data;

package body resource_map_inventory is

   function get_synchronization_tasks_partition_object return ptr_synchronization_tasks is
   begin
      return synchronization_tasks_partition;
   end get_synchronization_tasks_partition_object;

   protected body wait_all_quartieri is
      procedure all_quartieri_set is
      begin
         segnale:= True;
      end all_quartieri_set;

      entry wait_quartieri when segnale=True is
      begin
         segnale:= False;
      end wait_quartieri;
   end wait_all_quartieri;

   function create_risorse return set_resources is
      set: set_resources(1..get_num_task);
   begin
      for i in get_from_urbane..get_to_urbane loop
         set(i):= ptr_rt_segmento(get_urbane_segmento_resources(i));
      end loop;
      for i in get_from_ingressi..get_to_ingressi loop
         set(i):= ptr_rt_segmento(get_ingressi_segmento_resources(i));
      end loop;
      for i in get_from_incroci_a_4..get_to_incroci_a_4 loop
         set(i):= ptr_rt_segmento(get_incroci_a_4_segmento_resources(i));
      end loop;
      for i in get_from_incroci_a_3..get_to_incroci_a_3 loop
         set(i):= ptr_rt_segmento(get_incroci_a_3_segmento_resources(i));
      end loop;
      for i in get_from_rotonde_a_4..get_to_rotonde_a_4 loop
         set(i):= ptr_rt_segmento(get_rotonde_a_4_segmento_resources(i));
      end loop;
      for i in get_from_rotonde_a_3..get_to_rotonde_a_3 loop
         set(i):= ptr_rt_segmento(get_rotonde_a_3_segmento_resources(i));
      end loop;
      return set;
   end create_risorse;

   function get_quartiere_cfg(id_quartiere: Positive) return ptr_rt_quartiere_utilitites is
   begin
      return registro_ref_rt_quartieri(id_quartiere);
   end get_quartiere_cfg;

   local_abitanti: list_abitanti_quartiere:= create_array_abitanti(get_json_abitanti,get_from_abitanti,get_to_abitanti);
   local_pedoni: list_pedoni_quartiere:= create_array_pedoni(get_json_pedoni,get_from_abitanti,get_to_abitanti);
   local_bici: list_bici_quartiere:= create_array_bici(get_json_bici,get_from_abitanti,get_to_abitanti);
   local_auto: list_auto_quartiere:= create_array_auto(get_json_auto,get_from_abitanti,get_to_abitanti);
   registro_risorse: set_resources(1..get_num_task);

begin

   -- registrazione dell'oggetto che gestisce la sincronizzazione con tutti i quartieri
   registra_attesa_quartiere_obj(get_id_quartiere, ptr_rt_wait_all_quartieri(waiting_object));
   -- end

   -- crea mailbox task
   create_mailbox_entità(get_urbane,get_ingressi,get_incroci_a_4,get_incroci_a_3,get_rotonde_a_4,get_rotonde_a_3);
   registro_risorse:= create_risorse;
   -- end

   -- registrazione risorse segmenti
   registra_risorse_quartiere(get_id_quartiere,registro_risorse);
   -- end

   registra_gestore_semafori(get_id_quartiere,ptr_rt_handler_semafori_quartiere(semafori_quartiere_obj));

   registra_local_synchronized_obj(get_id_quartiere,ptr_rt_synchronization_tasks(synchronization_tasks_partition));

   --begin first checkpoint to get all ref of quartieri
   registra_quartiere(get_id_quartiere,ptr_rt_quartiere_utilitites(get_quartiere_utilities_obj));
   set_attesa_for_quartiere(get_id_quartiere);
   waiting_object.wait_quartieri;
   --ora tutti i rt_ref dei quartieri sono settati
   -- end checkpoint

   registro_ref_rt_quartieri:= get_ref_rt_quartieri;

   gps.registra_strade_quartiere(get_id_quartiere,get_urbane,get_ingressi);
   gps.registra_incroci_quartiere(get_id_quartiere,get_incroci_a_4,get_incroci_a_3,get_rotonde_a_4,get_rotonde_a_3);

   for i in registro_ref_rt_quartieri'Range loop
      registro_ref_rt_quartieri(i).registra_classe_locate_abitanti_quartiere(id_quartiere => get_id_quartiere, location_abitanti => ptr_rt_location_abitanti(get_locate_abitanti_quartiere));
      registro_ref_rt_quartieri(i).registra_abitanti(from_id_quartiere => get_id_quartiere, abitanti => local_abitanti, pedoni => local_pedoni, bici => local_bici, auto => local_auto);
      registro_ref_rt_quartieri(i).registra_mappa(get_id_quartiere);
   end loop;

   Put_Line("exit" & Positive'Image(get_id_quartiere) & " num task " & Positive'Image(get_num_task));

end resource_map_inventory;
