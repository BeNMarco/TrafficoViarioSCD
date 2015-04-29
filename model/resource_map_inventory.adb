with ada.Text_IO;

with global_data;
with remote_types;
with the_name_server;
with risorse_passive_utilities;
with mailbox_risorse_attive;
with handle_semafori;
with risorse_passive_data;
with System_error;
with System.RPC;
with Ada.Exceptions;
with synchronization_partitions;

use Ada.Text_IO;
with Ada.Strings.Unbounded;

use System_error;
use global_data;
use remote_types;
use the_name_server;
use risorse_passive_utilities;
use mailbox_risorse_attive;
use handle_semafori;
use risorse_passive_data;
use Ada.Strings.Unbounded;
use Ada.Exceptions;
use synchronization_partitions;

package body resource_map_inventory is
   
   function get_synchronization_tasks_partition_object return ptr_synchronization_tasks is
   begin
      return synchronization_tasks_partition_obj;
   end get_synchronization_tasks_partition_object;

   function create_risorse_ingressi return set_resources_ingressi is
      set: set_resources_ingressi(get_from_ingressi..get_to_ingressi);
   begin
      for i in get_from_ingressi..get_to_ingressi loop
         set(i):= ptr_rt_ingresso(get_ingressi_segmento_resources(i));
      end loop;
      return set;
   end create_risorse_ingressi;

   function create_risorse_urbane return set_resources_urbane is
      set: set_resources_urbane(get_from_urbane..get_to_urbane);
   begin
      for i in get_from_urbane..get_to_urbane loop
         set(i):= ptr_rt_urbana(get_urbane_segmento_resources(i));
      end loop;
      return set;
   end create_risorse_urbane;

   function create_risorse_incroci return set_resources_incroci is
      set: set_resources_incroci(get_from_incroci..get_to_incroci);
   begin
      for i in get_from_incroci_a_4..get_to_incroci_a_4 loop
         set(i):= ptr_rt_incrocio(get_incroci_a_4_segmento_resources(i));
      end loop;
      for i in get_from_incroci_a_3..get_to_incroci_a_3 loop
         set(i):= ptr_rt_incrocio(get_incroci_a_3_segmento_resources(i));
      end loop;
      return set;
   end create_risorse_incroci;

   procedure configure_quartiere is
      local_abitanti: list_abitanti_quartiere:= create_array_abitanti(get_json_abitanti,get_json_autobus,get_from_abitanti,get_to_abitanti);
      local_pedoni: list_pedoni_quartiere:= create_array_pedoni(get_json_pedoni,get_from_abitanti,get_to_abitanti);
      local_bici: list_bici_quartiere:= create_array_bici(get_json_bici,get_from_abitanti,get_to_abitanti);
      local_auto: list_auto_quartiere:= create_array_auto(get_json_auto,get_from_abitanti,get_to_abitanti);
      registro_risorse_ingressi: set_resources_ingressi(get_from_ingressi..get_to_ingressi);
      registro_risorse_urbane: set_resources_urbane(get_from_urbane..get_to_urbane);
      registro_risorse_incroci: set_resources_incroci(get_from_incroci..get_to_incroci);
      set: Boolean;
      raise_exception: Boolean:= False;
      error_state: Boolean:= False;
   begin
      set:= rci_parameters_are_set;
      gps:= get_server_gps;
      
      Put_Line("Inizio configurazione");
      create_synchronize_partitions_obj;
      synchronization_tasks_partition_obj:= new synchronization_tasks;

      
      -- registrazione dell'oggetto che gestisce la sincronizzazione con tutti i quartieri
      --registra_attesa_quartiere_obj(get_id_quartiere, ptr_rt_wait_all_quartieri(waiting_object));
      -- end
      -- crea mailbox task
      
      Put_Line("Creazione risorse");
      create_mailbox_entità(get_urbane,get_ingressi,get_incroci_a_4,get_incroci_a_3);
      registro_risorse_ingressi:= create_risorse_ingressi;
      registro_risorse_urbane:= create_risorse_urbane;
      registro_risorse_incroci:= create_risorse_incroci;
      -- end
      
      get_quartiere_utilities_obj.registra_cfg_quartiere(id_quartiere => get_id_quartiere, abitanti => local_abitanti, pedoni => local_pedoni, bici => local_bici, auto => local_auto, location_abitanti => ptr_rt_location_abitanti(get_locate_abitanti_quartiere));      

      set:= True;
      registra_quartiere(get_id_quartiere,
                         registro_risorse_ingressi,registro_risorse_urbane,registro_risorse_incroci,
                         ptr_rt_quartiere_entities_life(get_quartiere_entities_life_obj),
                         ptr_rt_gestore_bus_quartiere(get_gestore_bus_quartiere_obj),
                         ptr_rt_report_log(get_log_stallo_quartiere),
                         ptr_rt_quartiere_utilitites(get_quartiere_utilities_obj),
                         ptr_rt_synchronization_partitions_type(get_synchronization_partitions_object),
                         set);
      if set=False then
         log_system_error.set_error(name_server,error_state);
         -- quartiere già in uso
         Put_Line("quartiere " & Positive'Image(get_id_quartiere) & " già instanziato o sistema in chiusura.");
         return;
      end if;

      Put_Line("Regitrazione mappa al server gps");
      gps.registra_mappa_quartiere(get_id_quartiere,get_urbane,get_ingressi,get_incroci_a_4,get_incroci_a_3);
      Put_Line("Mappa registrata");
      quartiere_has_registered_map(get_id_quartiere);
        
   exception
      when System.RPC.Communication_Error =>
         raise;
         return;  
      when Error: others =>
         log_system_error.set_error(altro,error_state);
         Put_Line(Exception_Information(Error));
   end configure_quartiere;

end resource_map_inventory;
