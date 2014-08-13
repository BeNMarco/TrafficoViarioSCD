with global_data;
with remote_types;
with gps_utilities;
with configuration_cache_abitanti;
with configuration_posizione_abitanti;
with the_name_server;

use remote_types;
use gps_utilities;
use configuration_cache_abitanti;
use the_name_server;
use global_data;
use configuration_posizione_abitanti;

package configuration_server_parameter is
   pragma Elaborate_Body;

private
   gps: ptr_registro_strade_resource:= new registro_strade_resource;
   server_cache_abitanti_quartieri: ptr_cache_abitanti:= new cache_abitanti;
   server_ior_posizione_abitanti_quartieri: ptr_posizione_abitanti_quartieri:= new posizione_abitanti_quartieri;
end configuration_server_parameter;
