with Text_IO;

with configuration_cache_abitanti;
with risorse_passive_utilities;
with data_quartiere;
with the_name_server;
with global_data;
with remote_types;

use Text_IO;

use configuration_cache_abitanti;
use risorse_passive_utilities;
use data_quartiere;
use the_name_server;
use global_data;
use remote_types;

package body resource_mappa_inventory is

   local_abitanti: list_abitanti_quartiere:= create_array_abitanti(get_json_abitanti,get_from_abitanti,get_to_abitanti);
   local_pedoni: list_pedoni_quartiere:= create_array_pedoni(get_json_pedoni,get_from_abitanti,get_to_abitanti);
   local_bici: list_bici_quartiere:= create_array_bici(get_json_bici,get_from_abitanti,get_to_abitanti);
   local_auto: list_auto_quartiere:= create_array_auto(get_json_auto,get_from_abitanti,get_to_abitanti);
   server_cache: ptr_cache_abitanti_interface:= get_server_cache_abitanti;
   bounds: bound_quartieri(1..get_num_quartieri);

begin
   server_cache.registra_abitanti(from_id_quartiere => get_id_quartiere, abitanti => local_abitanti,
                                  pedoni => local_pedoni, bici => local_bici, auto => local_auto);
   server_cache.wait_cache_all_quartieri(bounds);

   declare
      temp_cache_abitanti: list_abitanti_temp:= server_cache.get_abitanti_quartieri;
      temp_cache_pedoni: list_pedoni_temp:= server_cache.get_pedoni_quartieri;
      temp_cache_bici: list_bici_temp:= server_cache.get_bici_quartieri;
      temp_cache_auto: list_auto_temp:= server_cache.get_auto_quartieri;
   begin
      server_cache.cache_quartiere_creata;
      for i in 1..get_num_quartieri loop
         abitanti(i):= new list_abitanti_quartiere(bounds(i).from_abitanti..bounds(i).to_abitanti);
         pedoni(i):= new list_pedoni_quartiere(bounds(i).from_abitanti..bounds(i).to_abitanti);
         bici(i):= new list_bici_quartiere(bounds(i).from_abitanti..bounds(i).to_abitanti);
         auto(i):= new list_auto_quartiere(bounds(i).from_abitanti..bounds(i).to_abitanti);
         for j in bounds(i).from_abitanti..bounds(i).to_abitanti loop
            abitanti(i)(j):= temp_cache_abitanti(i,j);
            pedoni(i)(j):= temp_cache_pedoni(i,j);
            bici(i)(j):= temp_cache_bici(i,j);
            auto(i)(j):= temp_cache_auto(i,j);
         end loop;
      end loop;
   end;

end resource_mappa_inventory;
