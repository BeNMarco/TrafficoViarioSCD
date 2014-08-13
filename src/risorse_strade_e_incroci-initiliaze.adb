with Text_IO;

with configuration_cache_abitanti;
with risorse_strade_e_incroci;
with risorse_passive_utilities;
with data_quartiere;
with the_name_server;
with global_data;
with remote_types;
with avvio_task;
with avvio_task.utilities;

use Text_IO;

use configuration_cache_abitanti;
use risorse_passive_utilities;
use risorse_strade_e_incroci;
use data_quartiere;
use the_name_server;
use global_data;
use remote_types;
use avvio_task;
use avvio_task.utilities;

package body risorse_strade_e_incroci.initiliaze is

   local_abitanti: list_abitanti_quartiere:= create_array_abitanti(get_json_abitanti,get_from_abitanti,get_to_abitanti);
   local_pedoni: list_pedoni_quartiere:= create_array_pedoni(get_json_pedoni,get_from_abitanti,get_to_abitanti);
   local_bici: list_bici_quartiere:= create_array_bici(get_json_bici,get_from_abitanti,get_to_abitanti);
   local_auto: list_auto_quartiere:= create_array_auto(get_json_auto,get_from_abitanti,get_to_abitanti);
   bounds: bound_quartieri(1..get_num_quartieri);

begin

   urbane_features:= create_array_urbane(json_roads => get_json_urbane, from => get_from_urbane, to => get_to_urbane);
   ingressi_features:= create_array_ingressi(json_roads => get_json_ingressi, from => get_from_ingressi, to => get_to_ingressi);
   incroci_a_4:= create_array_incroci_a_4(json_incroci => get_json_incroci_a_4, from => get_from_incroci_a_4, to => get_to_incroci_a_4);
   incroci_a_3:= create_array_incroci_a_3(json_incroci => get_json_incroci_a_3, from => get_from_incroci_a_3, to => get_to_incroci_a_3);
   rotonde_a_4:= create_array_incroci_a_4(json_incroci => get_json_rotonde_a_4, from => get_from_rotonde_a_4, to => get_to_rotonde_a_4);
   rotonde_a_3:= create_array_incroci_a_3(json_incroci => get_json_rotonde_a_3, from => get_from_rotonde_a_3, to => get_to_rotonde_a_3);

   server_cache:= get_server_cache_abitanti;
   server_cache.registra_abitanti(from_id_quartiere => get_id_quartiere, abitanti => local_abitanti,
                                  pedoni => local_pedoni, bici => local_bici, auto => local_auto);
   server_cache.wait_cache_all_quartieri(bounds);

   server_gps_abitanti:= get_server_abitanti_quartiere;
   server_gps_abitanti.registra_gps_abitanti_quartiere(id_quartiere => get_id_quartiere, location_abitanti => ptr_rt_location_abitanti(gps_abitanti));
   server_gps_abitanti.wait_gps_abitanti_all_quaritieri(id_quartiere => get_id_quartiere, gps_abitanti_quart => rt_gps_abitanti_quartieri);

   declare
      temp_cache_abitanti: list_abitanti_temp:= server_cache.get_abitanti_quartieri;
      temp_cache_pedoni: list_pedoni_temp:= server_cache.get_pedoni_quartieri;
      temp_cache_bici: list_bici_temp:= server_cache.get_bici_quartieri;
      temp_cache_auto: list_auto_temp:= server_cache.get_auto_quartieri;
   begin
      server_cache.cache_quartiere_creata;
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

end risorse_strade_e_incroci.initiliaze;
