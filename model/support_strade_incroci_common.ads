with Ada.Unchecked_Deallocation;
with strade_e_incroci_common;
with risorse_passive_data;
with model_webserver_communication_protocol_utilities;

use strade_e_incroci_common;
use risorse_passive_data;
use model_webserver_communication_protocol_utilities;
package support_strade_incroci_common is



   procedure Free_route_and_distance is new Ada.Unchecked_Deallocation
     (Object => route_and_distance, Name => ptr_route_and_distance);
   procedure Free_wrap_json_ar is new Ada.Unchecked_Deallocation
     (Object => wrap_json_ar, Name => ptr_JSON_Array);


end support_strade_incroci_common;
