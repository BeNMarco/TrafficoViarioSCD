with Ada.Text_IO;

with global_data;
with remote_types;
with gps_utilities;
with configuration_cache_abitanti;
with the_name_server;

use Ada.Text_IO;

use remote_types;
use gps_utilities;
use configuration_cache_abitanti;
use the_name_server;
use global_data;


package body configuration_server_parameter is

begin
   registra_server_cache_abitanti(ptr_cache_abitanti_interface(server_cache_abitanti_quartieri));
   registra_server_gps(ptr_gps_interface(gps));
   registra_server_posizione_abitanti_quartiere(ptr_rt_posizione_abitanti_quartieri(server_ior_posizione_abitanti_quartieri));
end configuration_server_parameter;
