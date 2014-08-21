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

   protected body registro_risorse_strade is

      procedure registra_risorse_quartiere(id_quartiere: Positive; set: set_resources) is
      begin
         registro(id_quartiere):= new set_resources'(set);
      end registra_risorse_quartiere;

      function get_id_risorsa_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_segmento is
      begin
         return registro(id_quartiere)(id_risorsa);
      end get_id_risorsa_quartiere;

   end registro_risorse_strade;

   procedure registra_synchronization_tasks_object(obj: ptr_rt_task_synchronization) is
   begin
      task_synchronization_obj:= obj;
   end registra_synchronization_tasks_object;

   function get_synchronization_tasks_object return ptr_rt_task_synchronization is
   begin
      loop
         delay until (Clock + 1.0);
         exit when task_synchronization_obj/=null;
      end loop;
      return task_synchronization_obj;
   end get_synchronization_tasks_object;

   procedure registra_risorse_quartiere(id_quartiere: Positive; set: set_resources) is
   begin
      registro_risorse_strade.registra_risorse_quartiere(id_quartiere,set);
   end registra_risorse_quartiere;

   function get_id_risorsa_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_segmento is
   begin
      return registro_risorse_strade.get_id_risorsa_quartiere(id_quartiere,id_risorsa);
   end get_id_risorsa_quartiere;

end the_name_server;
