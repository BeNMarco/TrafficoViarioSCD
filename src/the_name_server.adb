with Text_IO;
with Ada.Calendar;
with remote_types;
with partition_name;

use Text_IO;
use Ada.Calendar;
use remote_types;
use partition_name;

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

   procedure registra_gestore_semafori(id_quartiere: Positive; handler_semafori_quartiere: ptr_rt_handler_semafori_quartiere) is
   begin
      registro_gestori_semafori.registra_gestore_semafori(id_quartiere,handler_semafori_quartiere);
   end registra_gestore_semafori;
   function get_gestori_quartiere return handler_semafori is
   begin
      return registro_gestori_semafori.get_gestori_quartiere;
   end get_gestori_quartiere;

   function get_id_mappa return str_quartieri is
      pragma Warnings(off);
      id: Positive;
   begin
      get_my_mappa.registra_mappa(id);
      Put_Line(Natural'Image(id));
      if id=1 then
         return quartiere1;
      elsif id=2 then
         return quartiere2;
      elsif id=3 then
         return quartiere3;
      end if;
      pragma Warnings(on);
   end get_id_mappa;

   protected body registro_gestori_semafori is
      procedure registra_gestore_semafori(id_quartiere: Positive; handler_semafori_quartiere: ptr_rt_handler_semafori_quartiere) is
      begin
         registro(id_quartiere):= handler_semafori_quartiere;
      end registra_gestore_semafori;

      function get_gestori_quartiere return handler_semafori is
      begin
         return registro;
      end get_gestori_quartiere;

   end registro_gestori_semafori;

   protected body get_my_mappa is
      procedure registra_mappa(id: out Positive) is
      begin
         num_mappa:= num_mappa+1;
         id:= num_mappa;
      end registra_mappa;
   end get_my_mappa;

end the_name_server;
