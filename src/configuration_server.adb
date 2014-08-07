with Ada.Text_IO;
use Ada.Text_IO;

with global_data;
with remote_types;
with gps_utilities;
with configuration_cache_abitanti;
with the_name_server;


use remote_types;
use gps_utilities;
use configuration_cache_abitanti;
use the_name_server;
use global_data;

procedure configuration_server is
   gps: ptr_registro_strade_resource:= new registro_strade_resource;
begin
   registra_server_gps(ptr_gps_interface(gps));
end configuration_server;
