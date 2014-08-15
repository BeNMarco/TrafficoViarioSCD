with Text_IO;
with Ada.Calendar;

use Text_IO;
use Ada.Calendar;

package body the_name_server is

   procedure registra_server_gps(my_gps: ptr_gps_interface) is
   begin
      gps:= my_gps;
   end registra_server_gps;

   function get_server_gps return ptr_gps_interface is
   begin
      loop
         delay until (Clock + 1.0);
         exit when gps/=null;
      end loop;
      return gps;
   end get_server_gps;

end the_name_server;
