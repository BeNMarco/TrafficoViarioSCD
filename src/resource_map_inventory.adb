with global_data;
with remote_types;
with the_name_server;
with risorse_passive_utilities;
with configuration_synchronized_package;
with mailbox_risorse_attive;
with handle_semafori;

use global_data;
use remote_types;
use the_name_server;
use risorse_passive_utilities;
use configuration_synchronized_package;
use mailbox_risorse_attive;
use handle_semafori;

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

   procedure wait_settings_all_quartieri is
   begin
      waiting_cfg.wait_cfg;
   end wait_settings_all_quartieri;

   protected body location_abitanti is
      procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance) is
      begin
         percorsi(id_abitante):= new route_and_distance'(percorso);
      end set_percorso_abitante;
   end location_abitanti;

   protected body waiting_cfg is
      procedure incrementa_classi_locate_abitanti is
      begin
         num_classi_locate_abitanti:= num_classi_locate_abitanti+1;
      end incrementa_classi_locate_abitanti;
      procedure incrementa_num_quartieri_abitanti is
      begin
         num_abitanti_quartieri_registrati:= num_abitanti_quartieri_registrati+1;
      end incrementa_num_quartieri_abitanti;
      procedure incrementa_resource_mappa_quartieri is
      begin
         num_quartieri_resource_registrate:= num_quartieri_resource_registrate+1;
      end incrementa_resource_mappa_quartieri;
      entry wait_cfg when num_classi_locate_abitanti=get_num_quartieri and num_abitanti_quartieri_registrati=get_num_quartieri and num_quartieri_resource_registrate=get_num_quartieri is
      begin
         null;
      end wait_cfg;
   end waiting_cfg;

   function get_locate_abitanti_quartiere return ptr_location_abitanti is
   begin
      return locate_abitanti_quartiere;
   end get_locate_abitanti_quartiere;

   protected body quartiere_utilities is

      procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is
      begin
         rt_classi_locate_abitanti(id_quartiere):= location_abitanti;
         waiting_cfg.incrementa_classi_locate_abitanti;
      end registra_classe_locate_abitanti_quartiere;

      procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                                  bici: list_bici_quartiere; auto: list_auto_quartiere) is
      begin

         entità_abitanti(from_id_quartiere):= new list_abitanti_quartiere'(abitanti);
         entità_pedoni(from_id_quartiere):= new list_pedoni_quartiere'(pedoni);
         entità_bici(from_id_quartiere):= new list_bici_quartiere'(bici);
         entità_auto(from_id_quartiere):= new list_auto_quartiere'(auto);

         waiting_cfg.incrementa_num_quartieri_abitanti;
      end registra_abitanti;

      function get_abitante_quartiere(id_quartiere: Positive; id_abitante: Positive) return abitante is
         ab: abitante;
      begin
         return ab;
      end get_abitante_quartiere;

      function get_classi_locate_abitanti return gps_abitanti_quartieri is
      begin
         return rt_classi_locate_abitanti;
      end get_classi_locate_abitanti;

   end quartiere_utilities;

   function get_quartiere_utilities_obj return ptr_quartiere_utilities is
   begin
      return quartiere_cfg;
   end get_quartiere_utilities_obj;

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

   function get_urbana_from_id(index: Positive) return strada_urbana_features is
   begin
      return urbane_features(index);
   end get_urbana_from_id;
   function get_ingresso_from_id(index: Positive) return strada_ingresso_features is
   begin
      return ingressi_features(index);
   end get_ingresso_from_id;
   function get_incrocio_a_4_from_id(index: Positive) return list_road_incrocio_a_4 is
   begin
      return incroci_a_4(index);
   end get_incrocio_a_4_from_id;
   function get_incrocio_a_3_from_id(index: Positive) return list_road_incrocio_a_3 is
   begin
      return incroci_a_3(index);
   end get_incrocio_a_3_from_id;
   function get_rotonda_a_4_from_id(index: Positive) return list_road_incrocio_a_4 is
   begin
      return rotonde_a_4(index);
   end get_rotonda_a_4_from_id;
   function get_rotonda_a_3_from_id(index: Positive) return list_road_incrocio_a_3 is
   begin
      return rotonde_a_3(index);
   end get_rotonda_a_3_from_id;

   local_abitanti: list_abitanti_quartiere:= create_array_abitanti(get_json_abitanti,get_from_abitanti,get_to_abitanti);
   local_pedoni: list_pedoni_quartiere:= create_array_pedoni(get_json_pedoni,get_from_abitanti,get_to_abitanti);
   local_bici: list_bici_quartiere:= create_array_bici(get_json_bici,get_from_abitanti,get_to_abitanti);
   local_auto: list_auto_quartiere:= create_array_auto(get_json_auto,get_from_abitanti,get_to_abitanti);
   registro_ref_rt_quartieri: registro_quartieri(1..num_quartieri);
   registro_risorse: set_resources(1..get_num_task);
   mio: Natural:= 0;
begin
   -- registrazione dell'oggetto che gestisce la sincronizzazione con tutti i quartieri
   registra_attesa_quartiere_obj(get_id_quartiere, ptr_rt_wait_all_quartieri(waiting_object));
   if get_id_quartiere=2 then
      mio:= 1;
   else
      mio:= 2;
   end if;

   -- end

   -- crea mailbox task
   create_mailbox_entità(urbane_features,ingressi_features,incroci_a_4,incroci_a_3,rotonde_a_4,rotonde_a_3);
   registro_risorse:= create_risorse;
   -- end

   -- registrazione risorse segmenti
   registra_risorse_quartiere(get_id_quartiere,registro_risorse);
   -- end

   registra_gestore_semafori(get_id_quartiere,ptr_rt_handler_semafori_quartiere(semafori_quartiere_obj));

   --begin first checkpoint to get all ref of quartieri
   registra_quartiere(get_id_quartiere,ptr_rt_quartiere_utilitites(quartiere_cfg));
   set_attesa_for_quartiere(get_id_quartiere);
   waiting_object.wait_quartieri;
   --ora tutti i rt_ref dei quartieri sono settati
   -- end checkpoint

   registro_ref_rt_quartieri:= get_ref_rt_quartieri;

   for i in registro_ref_rt_quartieri'Range loop
      registro_ref_rt_quartieri(i).registra_classe_locate_abitanti_quartiere(id_quartiere => get_id_quartiere, location_abitanti => ptr_rt_location_abitanti(locate_abitanti_quartiere));
      registro_ref_rt_quartieri(i).registra_abitanti(from_id_quartiere => get_id_quartiere, abitanti => local_abitanti, pedoni => local_pedoni, bici => local_bici, auto => local_auto);
   end loop;

   gps.registra_strade_quartiere(get_id_quartiere,urbane_features,ingressi_features);
   gps.registra_incroci_quartiere(get_id_quartiere,incroci_a_4,incroci_a_3,rotonde_a_4,rotonde_a_3);
   waiting_cfg.incrementa_resource_mappa_quartieri;

   --waiting_cfg_quartieri.wait_cfg;

end resource_map_inventory;
