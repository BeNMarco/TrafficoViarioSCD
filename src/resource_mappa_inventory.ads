with GNATCOLL.JSON;

with JSON_Helper;
with risorse_strade_e_incroci;
with strade_e_incroci_common;
with data_quartiere;
with avvio_task.utilities;
with avvio_task;
with risorse_passive_utilities;

use GNATCOLL.JSON;

use JSON_Helper;
use risorse_strade_e_incroci;
use strade_e_incroci_common;
use data_quartiere;
use avvio_task.utilities;
use avvio_task;
use risorse_passive_utilities;

package resource_mappa_inventory is

   urbane_features: strade_urbane_features(from_urbane..to_urbane):=
     create_array_urbane(json_roads => json_urbane, from => from_urbane, to => to_urbane);

   ingressi_features: strade_ingresso_features(from_ingressi..to_ingressi):=
     create_array_ingressi(json_roads => json_ingressi, from => from_ingressi, to => to_ingressi);

   incroci_a_4: list_incroci_a_4(from_incroci_a_4..to_incroci_a_4):=
     create_array_incroci_a_4(json_incroci => json_incroci_a_4, from => from_incroci_a_4, to => to_incroci_a_4);
   incroci_a_3: list_incroci_a_3(from_incroci_a_3..to_incroci_a_3):=
     create_array_incroci_a_3(json_incroci => json_incroci_a_3, from => from_incroci_a_3, to => to_incroci_a_3);
   rotonde_a_4: list_incroci_a_4(from_rotonde_a_4..to_rotonde_a_4):=
     create_array_incroci_a_4(json_incroci => json_rotonde_a_4, from => from_rotonde_a_4, to => to_rotonde_a_4);
   rotonde_a_3: list_incroci_a_3(from_rotonde_a_3..to_rotonde_a_3):=
     create_array_incroci_a_3(json_incroci => json_rotonde_a_3, from => from_rotonde_a_3, to => to_rotonde_a_3);

   pedoni: list_pedoni(from_abitanti..to_abitanti):= create_array_pedoni;
   bici: list_bici(from_abitanti..to_abitanti):= create_array_bici;
   automobili: list_auto(from_abitanti..to_abitanti):= create_array_auto;
   abitanti: list_abitanti(from_abitanti..to_abitanti):= create_array_abitanti;

   percorso_abitanti: array(from_abitanti..to_abitanti) of stato_percorso;

end resource_mappa_inventory;
