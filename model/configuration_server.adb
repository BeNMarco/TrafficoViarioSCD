
with Ada.Text_IO;
use Ada.Text_IO;

with the_name_server;
with remote_types;
with gps_utilities;

use the_name_server;
use remote_types;
use gps_utilities;

procedure configuration_server is
   gps: ptr_registro_strade_resource;
   all_ok: Boolean:= True;
begin
   gps:= new registro_strade_resource(get_num_quartieri);
   registra_server_gps(ptr_gps_interface(gps),all_ok);
   if all_ok=False then
      -- server già registrato
      return;
   end if;

   loop
      delay 1.0;
      begin
         if is_server_registered then
            null;
         end if;
      exception
         when others =>
            return;
      end;
      exit when gps.has_to_been_closed;

   end loop;

   set_server_closure;
   Put_Line("Il server è stato chiuso.");
end configuration_server;
