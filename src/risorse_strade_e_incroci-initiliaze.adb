with Text_IO;
with Ada.Calendar;

with configuration_cache_abitanti;
with risorse_strade_e_incroci;
with risorse_passive_utilities;
with data_quartiere;
with the_name_server;
with global_data;
with remote_types;
with avvio_task;
with avvio_task.utilities;
with configuration_synchronized_package;
with configuration_posizione_abitanti;
with configuration_cache_abitanti;

use Text_IO;
use Ada.Calendar;

use configuration_cache_abitanti;
use risorse_passive_utilities;
use risorse_strade_e_incroci;
use data_quartiere;
use the_name_server;
use global_data;
use remote_types;
use avvio_task;
use avvio_task.utilities;
use configuration_synchronized_package;
use configuration_posizione_abitanti;
use configuration_cache_abitanti;

package body risorse_strade_e_incroci.initiliaze is

   local_abitanti: list_abitanti_quartiere:= create_array_abitanti(get_json_abitanti,get_from_abitanti,get_to_abitanti);
   local_pedoni: list_pedoni_quartiere:= create_array_pedoni(get_json_pedoni,get_from_abitanti,get_to_abitanti);
   local_bici: list_bici_quartiere:= create_array_bici(get_json_bici,get_from_abitanti,get_to_abitanti);
   local_auto: list_auto_quartiere:= create_array_auto(get_json_auto,get_from_abitanti,get_to_abitanti);
   bounds: bound_quartieri(1..get_num_quartieri);

begin
   -- registrazione dell'oggetto che gestisce la sincronizzazione con tutti i quartieri
   registra_attesa_quartiere_obj(get_id_quartiere, ptr_rt_wait_all_quartieri(waiting_object));
   -- end

   -- begin get classi remote per ottenere percorsi e locazione abitanti quartieri
   registra_classe_locate_abitanti_quartiere(get_id_quartiere, ptr_rt_location_abitanti(locate_abitanti_quartiere));
   -- checkpoint 1 per ottenere classi remote degli abitanti
   set_attesa_for_quartiere(get_id_quartiere);
   waiting_object.wait_quartieri;
   -- end checkpoint
   rt_classi_locate_abitanti:= get_classi_locate_abitanti_all_quaritieri;
   -- end

   -- begin sub per ottenere in locale una cache degli abitanti/pedoni/bici/auto di tutti i quartieri
   registra_abitanti(from_id_quartiere => get_id_quartiere, abitanti => local_abitanti,
                     pedoni => local_pedoni, bici => local_bici, auto => local_auto);
   -- checkpoint 2 per ottenere cache abitanti
   set_attesa_for_quartiere(get_id_quartiere);
   waiting_object.wait_quartieri;
   -- end checkpoint
   get_bound_quartieri(bounds);

   min_length_pedoni:= cfg_get_min_length_entità(entity => pedone_entity);
   min_length_bici:= cfg_get_min_length_entità(entity => bici_entity);
   min_length_auto:= cfg_get_min_length_entità(entity => auto_entity);

   declare
      temp_cache_abitanti: list_abitanti_temp:= get_abitanti_quartieri;
      temp_cache_pedoni: list_pedoni_temp:= get_pedoni_quartieri;
      temp_cache_bici: list_bici_temp:= get_bici_quartieri;
      temp_cache_auto: list_auto_temp:= get_auto_quartieri;
   begin
      cache_quartiere_creata;
      for i in 1..get_num_quartieri loop
         entità_abitanti(i):= new list_abitanti_quartiere(bounds(i).from_abitanti..bounds(i).to_abitanti);
         entità_pedoni(i):= new list_pedoni_quartiere(bounds(i).from_abitanti..bounds(i).to_abitanti);
         entità_bici(i):= new list_bici_quartiere(bounds(i).from_abitanti..bounds(i).to_abitanti);
         entità_auto(i):= new list_auto_quartiere(bounds(i).from_abitanti..bounds(i).to_abitanti);
         for j in bounds(i).from_abitanti..bounds(i).to_abitanti loop
            entità_abitanti(i)(j):= temp_cache_abitanti(i,j);
            entità_pedoni(i)(j):= temp_cache_pedoni(i,j);
            entità_bici(i)(j):= temp_cache_bici(i,j);
            entità_auto(i)(j):= temp_cache_auto(i,j);
         end loop;
      end loop;
   end;
   -- end

   urbane_features:= create_array_urbane(json_roads => get_json_urbane, from => get_from_urbane, to => get_to_urbane);
   ingressi_features:= create_array_ingressi(json_roads => get_json_ingressi, from => get_from_ingressi, to => get_to_ingressi);
   incroci_a_4:= create_array_incroci_a_4(json_incroci => get_json_incroci_a_4, from => get_from_incroci_a_4, to => get_to_incroci_a_4);
   incroci_a_3:= create_array_incroci_a_3(json_incroci => get_json_incroci_a_3, from => get_from_incroci_a_3, to => get_to_incroci_a_3);
   rotonde_a_4:= create_array_rotonde_a_4(json_incroci => get_json_rotonde_a_4, from => get_from_rotonde_a_4, to => get_to_rotonde_a_4);
   rotonde_a_3:= create_array_rotonde_a_3(json_incroci => get_json_rotonde_a_3, from => get_from_rotonde_a_3, to => get_to_rotonde_a_3);

   gps.registra_urbane_quartiere(get_id_quartiere, urbane_features);
   gps.registra_ingressi_quartiere(get_id_quartiere,ingressi_features);
   -- checkpoint 3 per permettere la costruzione del grafo nel server gps
   set_attesa_for_quartiere(get_id_quartiere);
   waiting_object.wait_quartieri;
   -- end checkpoint
   -- prima di registrare gli incroci è necessario che le urbane e gli ingressi di tt i quartieri siano registrate
   gps.registra_incroci_quartiere(get_id_quartiere,incroci_a_4,incroci_a_3,rotonde_a_4,rotonde_a_3);

   configure_tasks;
   -- begin checkpoint 4 ovvero i thread dei quartieri aspettano che gli altri quartieri finiscano le configurazioni
   set_attesa_for_quartiere(get_id_quartiere);

end risorse_strade_e_incroci.initiliaze;
