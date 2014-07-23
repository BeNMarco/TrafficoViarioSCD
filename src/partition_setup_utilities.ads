with GNATCOLL.JSON;

with strade_common.strade_features;

use GNATCOLL.JSON;

use strade_common.strade_features;

package partition_setup_utilities is

   -- begin catalogo urbane
   urbane_segmento_resources: ptr_resource_segmenti_strade;
   -- end catalogo urbane

   -- begin catalogo ingressi
   ingressi_segmento_resources: ptr_resource_segmenti_strade;
   -- end catalogo ingressi

   -- begin catalogo incroci
   incroci_segmenti_resources: ptr_resource_segmenti_strade;
   -- end catalogo incroci

   function create_array_strade(json_roads: JSON_array) return strade_urbane_features;

   function create_array_ingressi(json_roads: JSON_array) return strade_ingresso_features;

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;
   function create_array_incroci_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;
   function create_array_incroci_a_2(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_2;

end partition_setup_utilities;
