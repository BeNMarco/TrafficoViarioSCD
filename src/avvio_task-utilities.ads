with GNATCOLL.JSON;

with strade_e_incroci_common;
with risorse_strade_e_incroci;
with data_quartiere;

use GNATCOLL.JSON;

use strade_e_incroci_common;
use risorse_strade_e_incroci;
use data_quartiere;

package avvio_task.utilities is

   function create_array_urbane(json_roads: JSON_array; from: Natural; to: Natural) return strade_urbane_features;

   function create_array_ingressi(json_roads: JSON_array; from: Natural; to: Natural) return strade_ingresso_features;

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;

   function create_array_incroci_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;

   function create_array_rotonde_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;

   function create_array_rotonde_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;

   procedure print_percorso(route: percorso);

   procedure configure_tasks;

private

   urbane_segmento_resources: ptr_resource_segmenti_strade;
   ingressi_segmento_resources: ptr_resource_segmenti_strade;
   incroci_a_4_segmento_resources: ptr_resource_segmenti_strade;
   incroci_a_3_segmento_resources: ptr_resource_segmenti_strade;
   rotonde_a_4_segmento_resources: ptr_resource_segmenti_strade;
   rotonde_a_3_segmento_resources: ptr_resource_segmenti_strade;

end avvio_task.utilities;
