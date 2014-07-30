with GNATCOLL.JSON;

with strade_e_incroci_common;
with risorse_strade_e_incroci;

use GNATCOLL.JSON;

use strade_e_incroci_common;
use risorse_strade_e_incroci;

package partition_setup_utilities is

   urbane_segmento_resources: ptr_resource_segmenti_strade;
   ingressi_segmento_resources: ptr_resource_segmenti_strade;
   incroci_a_4_segmenti_resources: ptr_resource_segmenti_strade;
   incroci_a_3_segmenti_resources: ptr_resource_segmenti_strade;

   function create_array_urbane(json_roads: JSON_array; from: Natural; to: Natural) return strade_urbane_features;

   function create_array_ingressi(json_roads: JSON_array; from: Natural; to: Natural) return strade_ingresso_features;

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural;
                                     from_urbane: Natural; from_ingressi: Natural) return list_incroci_a_4;
   function create_array_incroci_a_3(json_incroci: JSON_array; from: Natural; to: Natural;
                                     from_urbane: Natural; from_ingressi: Natural) return list_incroci_a_3;

   procedure print_percorso(route: access percorso);

end partition_setup_utilities;
