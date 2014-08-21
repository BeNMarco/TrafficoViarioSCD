with GNATCOLL.JSON;

with strade_e_incroci_common;
with data_quartiere;
with remote_types;

use GNATCOLL.JSON;

use strade_e_incroci_common;
use data_quartiere;
use remote_types;

package risorse_mappa_utilities is

   function create_array_urbane(json_roads: JSON_array; from: Natural; to: Natural) return strade_urbane_features;

   function create_array_ingressi(json_roads: JSON_array; from: Natural; to: Natural) return strade_ingresso_features;

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;

   function create_array_incroci_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;

   function create_array_rotonde_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;

   function create_array_rotonde_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;

   procedure print_percorso(route: percorso);

end risorse_mappa_utilities;
