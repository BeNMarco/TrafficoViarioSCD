with Text_IO;
with Ada.Calendar;
with remote_types;

use Text_IO;
use Ada.Calendar;
use remote_types;

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

   procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites) is
   begin
      registro_ref_quartieri.registra_quartiere(id_quartiere,rt_quartiere);
   end registra_quartiere;

   function get_ref_rt_quartieri return registro_quartieri is
   begin
      return registro_ref_quartieri.get_ref_rt_quartieri;
   end get_ref_rt_quartieri;

   protected body registro_ref_quartieri is
      procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites) is
      begin
         registro(id_quartiere):= rt_quartiere;
      end registra_quartiere;

      function get_ref_rt_quartieri return registro_quartieri is
      begin
         return registro;
      end get_ref_rt_quartieri;
   end registro_ref_quartieri;

end the_name_server;
