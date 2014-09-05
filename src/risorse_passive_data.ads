with risorse_mappa_utilities;
with strade_e_incroci_common;
with data_quartiere;

use risorse_mappa_utilities;
use strade_e_incroci_common;
use data_quartiere;

package risorse_passive_data is

   function get_urbana_from_id(index: Positive) return strada_urbana_features;
   function get_ingresso_from_id(index: Positive) return strada_ingresso_features;
   function get_incrocio_a_4_from_id(index: Positive) return list_road_incrocio_a_4;
   function get_incrocio_a_3_from_id(index: Positive) return list_road_incrocio_a_3;
   function get_rotonda_a_4_from_id(index: Positive) return list_road_incrocio_a_4;
   function get_rotonda_a_3_from_id(index: Positive) return list_road_incrocio_a_3;

   function get_urbane return strade_urbane_features;
   function get_ingressi return strade_ingresso_features;
   function get_incroci_a_4 return list_incroci_a_4;
   function get_incroci_a_3 return list_incroci_a_3;
   function get_rotonde_a_4 return list_incroci_a_4;
   function get_rotonde_a_3 return list_incroci_a_3;

private

   urbane_features: strade_urbane_features:= create_array_urbane(json_roads => get_json_urbane, from => get_from_urbane, to => get_to_urbane);
   ingressi_features: strade_ingresso_features:= create_array_ingressi(json_roads => get_json_ingressi, from => get_from_ingressi, to => get_to_ingressi);
   incroci_a_4: list_incroci_a_4:= create_array_incroci_a_4(json_incroci => get_json_incroci_a_4, from => get_from_incroci_a_4, to => get_to_incroci_a_4);
   incroci_a_3: list_incroci_a_3:= create_array_incroci_a_3(json_incroci => get_json_incroci_a_3, from => get_from_incroci_a_3, to => get_to_incroci_a_3);
   rotonde_a_4: list_incroci_a_4:= create_array_rotonde_a_4(json_incroci => get_json_rotonde_a_4, from => get_from_rotonde_a_4, to => get_to_rotonde_a_4);
   rotonde_a_3: list_incroci_a_3:= create_array_rotonde_a_3(json_incroci => get_json_rotonde_a_3, from => get_from_rotonde_a_3, to => get_to_rotonde_a_3);

   traiettorie_incroci: traiettorie_incrocio:= create_traiettorie_incrocio(json_traiettorie => get_json_traiettorie_incrocio);
   traiettorie_ingressi: traiettorie_ingresso:= create_traiettorie_ingresso(json_traiettorie => get_json_traiettorie_ingresso);

end risorse_passive_data;
