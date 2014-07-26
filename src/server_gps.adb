with Ada.Text_IO;
use Ada.Text_IO;

with remote_types;
with server_gps_utilities;
with the_name_server;

use remote_types;
use server_gps_utilities;
use the_name_server;

procedure server_gps is
   gps: ptr_registro_strade_resource:= new registro_strade_resource;
begin
   registra_server_gps(ptr_gps_interface(gps));
end server_gps;
