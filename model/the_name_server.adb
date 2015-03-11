with Text_IO;
with Ada.Calendar;
with remote_types;

use Text_IO;
use Ada.Calendar;
use remote_types;

package body the_name_server is

   procedure registra_quartiere_log(id_quartiere: Positive; file_log: ptr_rt_report_log) is
   begin
      registro_log_quartieri(id_quartiere):= file_log;
   end registra_quartiere_log;

   function get_log_quartiere(id_quartiere: Positive) return ptr_rt_report_log is
   begin
      return registro_log_quartieri(id_quartiere);
   end get_log_quartiere;

   procedure registra_webserver(my_web: Access_WebServer_Remote_Interface) is
   begin
      web:= my_web;
   end registra_webserver;

   function get_webServer return Access_WebServer_Remote_Interface is
   begin
      loop
         delay until (Clock + 1.0);
         exit when web/=null;
      end loop;
      return web;
   end get_webServer;

   procedure registra_server_gps(my_gps: ptr_gps_interface) is
   begin
      gps:= my_gps;
   end registra_server_gps;

   function get_server_gps return ptr_gps_interface is
   begin
      while gps=null loop
         delay until (Clock + 1.0);
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

   function get_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites is
   begin
      while registro_ref_quartieri.get_ref_quartiere(id_quartiere)=null loop
         delay until (Clock + 1.0);
      end loop;
      return registro_ref_quartieri.get_ref_quartiere(id_quartiere);
   end get_ref_quartiere;

   procedure registra_local_synchronized_obj(id_quartiere: Positive; obj: ptr_rt_synchronization_tasks) is
   begin
      registro_local_synchronized_objects.registra_local_synchronized_obj(id_quartiere,obj);
   end registra_local_synchronized_obj;

   function get_ref_local_synchronized_obj return registro_local_synchronized_obj is
   begin
      return registro_local_synchronized_objects.get_ref_local_synchronized_obj;
   end get_ref_local_synchronized_obj;

   protected body registro_ref_quartieri is
      procedure registra_quartiere(id_quartiere: Positive; rt_quartiere: ptr_rt_quartiere_utilitites) is
      begin
         registro(id_quartiere):= rt_quartiere;
      end registra_quartiere;

      function get_ref_rt_quartieri return registro_quartieri is
      begin
         return registro;
      end get_ref_rt_quartieri;

      function get_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites is
      begin
         return registro(id_quartiere);
      end get_ref_quartiere;

   end registro_ref_quartieri;

   protected body registro_risorse_strade is

      procedure registra_risorse_quartiere(id_quartiere: Positive; set_ingressi: set_resources_ingressi; set_urbane: set_resources_urbane; set_incroci: set_resources_incroci) is
      begin
         registro_ingressi(id_quartiere):= new set_resources_ingressi'(set_ingressi);
         registro_urbane(id_quartiere):= new set_resources_urbane'(set_urbane);
         registro_incroci(id_quartiere):= new set_resources_incroci'(set_incroci);
      end registra_risorse_quartiere;

      function get_id_ingresso_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_ingresso is
      begin
         return registro_ingressi(id_quartiere)(id_risorsa);
      end get_id_ingresso_quartiere;

      function get_id_urbana_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_urbana is
      begin
         return registro_urbane(id_quartiere)(id_risorsa);
      end get_id_urbana_quartiere;

      function get_id_incrocio_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_incrocio is
      begin
         Put_Line(Positive'Image(id_risorsa) & " " & Positive'Image(id_quartiere));
         return registro_incroci(id_quartiere)(id_risorsa);
      end get_id_incrocio_quartiere;

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

   procedure registra_risorse_quartiere(id_quartiere: Positive; set_ingressi: set_resources_ingressi; set_urbane: set_resources_urbane; set_incroci: set_resources_incroci) is
   begin
      registro_risorse_strade.registra_risorse_quartiere(id_quartiere,set_ingressi,set_urbane,set_incroci);
   end registra_risorse_quartiere;

   function get_id_ingresso_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_ingresso is
   begin
      return registro_risorse_strade.get_id_ingresso_quartiere(id_quartiere,id_risorsa);
   end get_id_ingresso_quartiere;

   function get_id_urbana_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_urbana is
   begin
      return registro_risorse_strade.get_id_urbana_quartiere(id_quartiere,id_risorsa);
   end get_id_urbana_quartiere;

   function get_id_incrocio_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_incrocio is
   begin
      Put_Line(Positive'Image(id_quartiere) & " " & Positive'Image(id_risorsa));
      return registro_risorse_strade.get_id_incrocio_quartiere(id_quartiere,id_risorsa);
   end get_id_incrocio_quartiere;

   procedure registra_gestore_semafori(id_quartiere: Positive; handler_semafori_quartiere: ptr_rt_handler_semafori_quartiere) is
   begin
      registro_gestori_semafori.registra_gestore_semafori(id_quartiere,handler_semafori_quartiere);
   end registra_gestore_semafori;
   function get_gestori_quartiere return handler_semafori is
   begin
      return registro_gestori_semafori.get_gestori_quartiere;
   end get_gestori_quartiere;

   procedure registra_quartiere_entities_life(id_quartiere: Positive; obj: ptr_rt_quartiere_entities_life) is
   begin
      registro_quartiere_entities_life.registra_quartiere_entities_life(id_quartiere,obj);
   end registra_quartiere_entities_life;

   function get_quartiere_entities_life(id_quartiere: Positive) return ptr_rt_quartiere_entities_life is
   begin
      return registro_quartiere_entities_life.get_quartiere_entities_life(id_quartiere);
   end get_quartiere_entities_life;

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

   protected body registro_local_synchronized_objects is

      procedure registra_local_synchronized_obj(id_quartiere: Positive; obj: ptr_rt_synchronization_tasks) is
      begin
         registro(id_quartiere):= obj;
      end registra_local_synchronized_obj;

      function get_ref_local_synchronized_obj return registro_local_synchronized_obj is
      begin
         return registro;
      end get_ref_local_synchronized_obj;

   end registro_local_synchronized_objects;

   protected body registro_quartiere_entities_life is
      procedure registra_quartiere_entities_life(id_quartiere: Positive; obj: ptr_rt_quartiere_entities_life) is
      begin
         registro(id_quartiere):= obj;
      end registra_quartiere_entities_life;

      function get_quartiere_entities_life(id_quartiere: Positive) return ptr_rt_quartiere_entities_life is
      begin
         return registro(id_quartiere);
      end get_quartiere_entities_life;

   end registro_quartiere_entities_life;

end the_name_server;
