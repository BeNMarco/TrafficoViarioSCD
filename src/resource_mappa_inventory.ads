with GNATCOLL.JSON;

with JSON_Helper;
with risorse_strade_e_incroci;
with strade_e_incroci_common;
with data_quartiere;
with avvio_task.utilities;
with avvio_task;
with risorse_passive_utilities;
with configuration_cache_abitanti;
with global_data;

use GNATCOLL.JSON;

use JSON_Helper;
use risorse_strade_e_incroci;
use strade_e_incroci_common;
use data_quartiere;
use avvio_task.utilities;
use avvio_task;
use risorse_passive_utilities;
use configuration_cache_abitanti;
use global_data;

package resource_mappa_inventory is
   pragma Elaborate_Body;
private

   urbane_features: strade_urbane_features(get_from_urbane..get_to_urbane):=
     create_array_urbane(json_roads => get_json_urbane, from => get_from_urbane, to => get_to_urbane);

   ingressi_features: strade_ingresso_features(get_from_ingressi..get_to_ingressi):=
     create_array_ingressi(json_roads => get_json_ingressi, from => get_from_ingressi, to => get_to_ingressi);

   incroci_a_4: list_incroci_a_4(get_from_incroci_a_4..get_to_incroci_a_4):=
     create_array_incroci_a_4(json_incroci => get_json_incroci_a_4, from => get_from_incroci_a_4, to => get_to_incroci_a_4);
   incroci_a_3: list_incroci_a_3(get_from_incroci_a_3..get_to_incroci_a_3):=
     create_array_incroci_a_3(json_incroci => get_json_incroci_a_3, from => get_from_incroci_a_3, to => get_to_incroci_a_3);
   rotonde_a_4: list_incroci_a_4(get_from_rotonde_a_4..get_to_rotonde_a_4):=
     create_array_incroci_a_4(json_incroci => get_json_rotonde_a_4, from => get_from_rotonde_a_4, to => get_to_rotonde_a_4);
   rotonde_a_3: list_incroci_a_3(get_from_rotonde_a_3..get_to_rotonde_a_3):=
     create_array_incroci_a_3(json_incroci => get_json_rotonde_a_3, from => get_from_rotonde_a_3, to => get_to_rotonde_a_3);

   abitanti: list_abitanti_quartieri(1..get_num_quartieri);
   pedoni: list_pedoni_quartieri(1..get_num_quartieri);
   bici: list_bici_quartieri(1..get_num_quartieri);
   auto: list_auto_quartieri(1..get_num_quartieri);
   --percorso_abitanti: array(from_abitanti..to_abitanti) of stato_percorso;

end resource_mappa_inventory;
