with GNATCOLL.json;

with strade_e_incroci_common;

use GNATCOLL.json;

use strade_e_incroci_common;

package risorse_passive_utilities is

   function create_array_abitanti(json_abitanti: JSON_array; from: Natural; to: Natural) return list_abitanti_quartiere;
   function create_array_pedoni(json_pedoni: JSON_array; from: Natural; to: Natural) return list_pedoni_quartiere;
   function create_array_bici(json_bici: JSON_array; from: Natural; to: Natural) return list_bici_quartiere;
   function create_array_auto(json_auto: JSON_array; from: Natural; to: Natural) return list_auto_quartiere;

end risorse_passive_utilities;
