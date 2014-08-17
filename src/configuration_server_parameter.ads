with global_data;
with remote_types;
with gps_utilities;
with the_name_server;

use remote_types;
use gps_utilities;
use the_name_server;
use global_data;

package configuration_server_parameter is
   pragma Elaborate_Body;

private
   gps: ptr_registro_strade_resource:= new registro_strade_resource;
end configuration_server_parameter;
