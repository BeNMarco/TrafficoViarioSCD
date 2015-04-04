with Text_IO;
with Ada.Calendar;
with remote_types;
with System.RPC;

use Text_IO;
use Ada.Calendar;
use remote_types;

package body the_name_server is

   function is_server_registered return Boolean is
   begin
      return servers_ref.is_server_registered;
   end is_server_registered;
   function is_web_server_registered return Boolean is
   begin
      return servers_ref.is_web_server_registered;
   end is_web_server_registered;
   function is_quartiere_registered(id: Positive) return Boolean is
   begin
      return cfg_quartieri_obj.is_quartiere_registered(id);
   end is_quartiere_registered;

   protected body servers_ref is

      function server_is_closed return Boolean is
      begin
         return server_is_closed_val;
      end server_is_closed;
      procedure set_server_closure is
      begin
         server_is_closed_val:= True;
      end set_server_closure;
      function web_server_is_closed return Boolean is
      begin
         return web_server_is_closed_val;
      end web_server_is_closed;
      procedure set_web_server_closure is
      begin
         web_server_is_closed_val:= True;
      end set_web_server_closure;

      procedure registra_webserver(my_web: Access_WebServer_Remote_Interface) is
      begin
         registered(2):= True;
         web:= my_web;
      end registra_webserver;

      procedure registra_server_gps(my_gps: ptr_gps_interface) is
      begin
         registered(1):= True;
         gps:= my_gps;
      end registra_server_gps;

      function get_server_gps return ptr_gps_interface is
      begin
         return gps;
      end get_server_gps;

      function get_webServer return Access_WebServer_Remote_Interface is
      begin
         return web;
      end get_webServer;

      function is_server_registered return Boolean is
      begin
         return registered(1);
      end is_server_registered;

      function is_web_server_registered return Boolean is
      begin
         return registered(2);
      end is_web_server_registered;

   end servers_ref;

   procedure configure_num_quartieri_name_server(numero_quartieri: Positive) is
   begin
      num_quartieri:= numero_quartieri;
      cfg_quartieri_obj:= new cfg_quartieri(numero_quartieri);
   end configure_num_quartieri_name_server;

   function rci_parameters_are_set return Boolean is
   begin
      while cfg_quartieri_obj=null loop
         delay until (Clock + 1.0);
         if signal_quit_arrived then
            return False;
         end if;
      end loop;
      return True;
   end rci_parameters_are_set;

   function get_num_quartieri return Positive is
   begin
      while num_quartieri=0 loop
         delay until (Clock + 1.0);
      end loop;
      return num_quartieri;
   end get_num_quartieri;

   procedure quit_signal is
   begin
      cfg_quartieri_obj.quit_signal;
   end quit_signal;

   procedure quartiere_non_ha_nuove_partizioni(id_quartiere: Positive) is
   begin
      cfg_quartieri_obj.quartiere_non_ha_nuove_partizioni(id_quartiere);
   end quartiere_non_ha_nuove_partizioni;

   function signal_quit_arrived return Boolean is
   begin
      return cfg_quartieri_obj.signal_quit_arrived;
   end signal_quit_arrived;

   function all_quartieri_has_finish_operations return Boolean is
   begin
      return cfg_quartieri_obj.all_quartieri_has_finish_operations;
   end all_quartieri_has_finish_operations;

   procedure quartiere_has_finished_all_operations(id_quartiere: Positive) is
   begin
      cfg_quartieri_obj.quartiere_has_finished_all_operations(id_quartiere);
   end quartiere_has_finished_all_operations;

   function has_quartiere_finish_all_operations(id_quartiere: Positive) return Boolean is
   begin
      return cfg_quartieri_obj.has_quartiere_finish_all_operations(id_quartiere);
   end has_quartiere_finish_all_operations;

   function get_log_quartiere(id_quartiere: Positive) return ptr_rt_report_log is
   begin
      return cfg_quartieri_obj.get_log_quartiere(id_quartiere);
   end get_log_quartiere;

   procedure registra_webserver(my_web: Access_WebServer_Remote_Interface; all_ok: in out Boolean) is
   begin
      all_ok:= True;
      if servers_ref.get_webServer/=null then
         all_ok:= False;
         return;
      end if;
      servers_ref.registra_webserver(my_web);
   end registra_webserver;

   function get_webServer return Access_WebServer_Remote_Interface is
   begin
      while servers_ref.get_webServer=null loop
         delay until (Clock + 1.0);
         if signal_quit_arrived then
            return null;
         end if;
      end loop;
      return servers_ref.get_webServer;
   end get_webServer;

   procedure registra_server_gps(my_gps: ptr_gps_interface; all_ok: in out Boolean) is
   begin
      all_ok:= True;
      if servers_ref.get_server_gps/=null then
         all_ok:= False;
         return;
      end if;
      servers_ref.registra_server_gps(my_gps);
   end registra_server_gps;

   function get_server_gps return ptr_gps_interface is
   begin
      while servers_ref.get_server_gps=null loop
         delay until (Clock + 1.0);
         if signal_quit_arrived then
            return null;
         end if;
      end loop;
      return servers_ref.get_server_gps;
   end get_server_gps;

   function server_is_closed return Boolean is
   begin
      return servers_ref.server_is_closed;
   end server_is_closed;
   procedure set_server_closure is
   begin
      servers_ref.set_server_closure;
   end set_server_closure;
   function web_server_is_closed return Boolean is
   begin
      return servers_ref.web_server_is_closed;
   end web_server_is_closed;
   procedure set_web_server_closure is
   begin
      servers_ref.set_web_server_closure;
   end set_web_server_closure;

   procedure registra_quartiere(id_quartiere: Positive;
                                set_ingressi: set_resources_ingressi; set_urbane: set_resources_urbane; set_incroci: set_resources_incroci;
                                entities_life: ptr_rt_quartiere_entities_life;
                                gestore_bus: ptr_rt_gestore_bus_quartiere;
                                report_log: ptr_rt_report_log;
                                quartiere_utilities: ptr_rt_quartiere_utilitites;
                                synch_local_obj: ptr_rt_synchronization_partitions_type;
                                all_ok: in out Boolean) is
      registered: Boolean:= True;
   begin
      begin
         all_ok:= True;
         if cfg_quartieri_obj.get_ref_quartiere(id_quartiere)/=null then
            all_ok:= False;
            return;
         end if;
         cfg_quartieri_obj.registra_quartiere(id_quartiere,
                                              set_ingressi,set_urbane,set_incroci,
                                              entities_life,gestore_bus,report_log,
                                              quartiere_utilities,synch_local_obj,
                                              registered);
         if registered=False then
            all_ok:= False;
         end if;
      exception
         when others =>
            -- ERRORE NELLA REGISTRAZIONE DEL QUARTIERE id_quartiere
            all_ok:= False;
      end;
   end registra_quartiere;

   procedure quartiere_has_registered_map(id_quartiere: Positive) is
   begin
      cfg_quartieri_obj.quartiere_has_registered_map(id_quartiere);
   end quartiere_has_registered_map;

   procedure quartiere_has_closed_tasks(id_quartiere: Positive) is
   begin
      cfg_quartieri_obj.quartiere_has_closed_tasks(id_quartiere);
   end quartiere_has_closed_tasks;

   function get_num_quartieri_up return Natural is
   begin
      return cfg_quartieri_obj.get_num_quartieri_up;
   end get_num_quartieri_up;

   protected body cfg_quartieri is
      procedure registra_quartiere(id_quartiere: Positive;
                                   set_ingressi: set_resources_ingressi; set_urbane: set_resources_urbane; set_incroci: set_resources_incroci;
                                   entities_life: ptr_rt_quartiere_entities_life;
                                   gestore_bus: ptr_rt_gestore_bus_quartiere;
                                   report_log: ptr_rt_report_log;
                                   quartiere_utilities: ptr_rt_quartiere_utilitites;
                                   synch_local_obj: ptr_rt_synchronization_partitions_type;
                                   all_ok: in out Boolean) is
      begin
         all_ok:= True;
         if quit then
            all_ok:= False;
         end if;

         registro_quartieri_util(id_quartiere):= quartiere_utilities;

         registro_log(id_quartiere):= report_log;

         if registro_ingressi(id_quartiere)=null then
            registro_ingressi(id_quartiere):= new set_resources_ingressi'(set_ingressi);
         else
            for i in registro_ingressi'Range loop
               registro_ingressi(id_quartiere)(i):= set_ingressi(i);
            end loop;
         end if;
         if registro_urbane(id_quartiere)=null then
            registro_urbane(id_quartiere):= new set_resources_urbane'(set_urbane);
         else
            for i in registro_urbane'Range loop
               registro_urbane(id_quartiere)(i):= set_urbane(i);
            end loop;
         end if;
         if registro_incroci(id_quartiere)=null then
            registro_incroci(id_quartiere):= new set_resources_incroci'(set_incroci);
         else
            for i in registro_incroci'Range loop
               registro_incroci(id_quartiere)(i):= set_incroci(i);
            end loop;
         end if;

         registro_lifes(id_quartiere):= entities_life;

         registro_bus(id_quartiere):= gestore_bus;

         registro_synch_quartieri(id_quartiere):= synch_local_obj;

         registered(id_quartiere):= True;

         num_quartieri_up:= num_quartieri_up+1;

      end registra_quartiere;

      procedure quartiere_has_registered_map(id_quartiere: Positive) is
      begin
         map_registered(id_quartiere):= True;
      end quartiere_has_registered_map;

      procedure quartiere_has_closed_tasks(id_quartiere: Positive) is
         segnale: Boolean:= True;
      begin
         quartiere_with_closed_tasks(id_quartiere):= True;
         for i in 1..max_num_quartieri loop
            if registro_quartieri_util(i)/=null then
               if quartiere_with_closed_tasks(i)=False then
                  segnale:= False;
               end if;
            end if;
         end loop;
         if segnale then
            for i in 1..max_num_quartieri loop
               if registro_quartieri_util(i)/=null then
                  registro_quartieri_util(i).all_can_be_closed;
               end if;
            end loop;
         end if;
      end quartiere_has_closed_tasks;

      procedure quit_signal is
      begin
         quit:= True;
      end quit_signal;

      function signal_quit_arrived return Boolean is
      begin
         return quit;
      end signal_quit_arrived;

      procedure quartiere_non_ha_nuove_partizioni(id_quartiere: Positive) is
         segnale: Boolean:= True;
      begin
         quartieri_without_new_partitions(id_quartiere):= True;
         for i in 1..max_num_quartieri loop
            if registro_quartieri_util(i)/=null and then quartieri_without_new_partitions(i)=False then
               segnale:= False;
            end if;
         end loop;
         if segnale then
            -- tutti i quartieri sono senza nuove partizioni
            for i in 1..max_num_quartieri loop
               if registro_quartieri_util(i)/=null then
                  registro_quartieri_util(i).close_system;
               end if;
            end loop;
         end if;
      end quartiere_non_ha_nuove_partizioni;

      function get_num_quartieri_up return Natural is
      begin
         return num_quartieri_up;
      end get_num_quartieri_up;

      function get_log_quartiere(id_quartiere: Positive) return ptr_rt_report_log is
      begin
         if registro_log(id_quartiere)/=null then
            return registro_log(id_quartiere);
         end if;
         return null;
      end get_log_quartiere;

      function get_ref_rt_quartieri return registro_quartieri is
      begin
         return registro_quartieri_util;
      end get_ref_rt_quartieri;

      function get_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites is
      begin
         if map_registered(id_quartiere) then
            return registro_quartieri_util(id_quartiere);
         else
            return null;
         end if;
      end get_ref_quartiere;

      function get_id_ingresso_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_ingresso is
      begin
         if registro_ingressi(id_quartiere)/=null then
            return registro_ingressi(id_quartiere)(id_risorsa);
         else
            return null;
         end if;
      end get_id_ingresso_quartiere;

      function get_id_urbana_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_urbana is
      begin
         if registro_urbane(id_quartiere)/=null then
            return registro_urbane(id_quartiere)(id_risorsa);
         else
            return null;
         end if;
      end get_id_urbana_quartiere;

      function get_id_incrocio_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_incrocio is
      begin
         if registro_incroci(id_quartiere)/=null then
            return registro_incroci(id_quartiere)(id_risorsa);
         else
            return null;
         end if;
      end get_id_incrocio_quartiere;

      function get_quartiere_entities_life(id_quartiere: Positive) return ptr_rt_quartiere_entities_life is
      begin
         return registro_lifes(id_quartiere);
      end get_quartiere_entities_life;

      function get_quartiere_gestore_bus(id_quartiere: Positive) return ptr_rt_gestore_bus_quartiere is
      begin
         return registro_bus(id_quartiere);
      end get_quartiere_gestore_bus;

      function get_registro_gestori_bus return registro_gestori_bus_quartieri is
      begin
         return registro_bus;
      end get_registro_gestori_bus;

      function get_synchronizer_quartiere(id_quartiere: Positive) return ptr_rt_synchronization_partitions_type is
      begin
         return registro_synch_quartieri(id_quartiere);
      end get_synchronizer_quartiere;

      function get_registro_quartieri return registro_quartieri is
         return_registro: registro_quartieri(1..num_quartieri):= (others => null);
      begin
         for i in 1..num_quartieri loop
            if map_registered(i) then
               return_registro(i):= registro_quartieri_util(i);
            end if;
         end loop;

         return return_registro;
      end get_registro_quartieri;

      function is_quartiere_registered(id: Positive) return Boolean is
      begin
         return registered(id);
      end is_quartiere_registered;

      function all_quartieri_has_finish_operations return Boolean is
      begin
         return all_system_can_be_closed;
      end all_quartieri_has_finish_operations;

      procedure quartiere_has_finished_all_operations(id_quartiere: Positive) is
         segnale: Boolean:= True;
      begin
         set_quartieri_finish_operations(id_quartiere):= True;
         for i in 1..max_num_quartieri loop
            if registro_quartieri_util(i)/=null then
               if set_quartieri_finish_operations(i)=False then
                  segnale:= False;
               end if;
            end if;
         end loop;
         if segnale then
            all_system_can_be_closed:= True;
         end if;
      end quartiere_has_finished_all_operations;

      function has_quartiere_finish_all_operations(id_quartiere: Positive) return Boolean is
      begin
         return set_quartieri_finish_operations(id_quartiere);
      end has_quartiere_finish_all_operations;

   end cfg_quartieri;

   function get_ref_rt_quartieri return registro_quartieri is
   begin
      return cfg_quartieri_obj.get_ref_rt_quartieri;
   end get_ref_rt_quartieri;

   function get_ref_quartiere(id_quartiere: Positive) return ptr_rt_quartiere_utilitites is
   begin
      return cfg_quartieri_obj.get_ref_quartiere(id_quartiere);
   end get_ref_quartiere;

   function get_id_ingresso_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_ingresso is
   begin
      return cfg_quartieri_obj.get_id_ingresso_quartiere(id_quartiere,id_risorsa);
   end get_id_ingresso_quartiere;

   function get_id_urbana_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_urbana is
   begin
      return cfg_quartieri_obj.get_id_urbana_quartiere(id_quartiere,id_risorsa);
   end get_id_urbana_quartiere;

   function get_id_incrocio_quartiere(id_quartiere: Positive; id_risorsa: Positive) return ptr_rt_incrocio is
   begin
      return cfg_quartieri_obj.get_id_incrocio_quartiere(id_quartiere,id_risorsa);
   end get_id_incrocio_quartiere;

   function get_quartiere_entities_life(id_quartiere: Positive) return ptr_rt_quartiere_entities_life is
   begin
      return cfg_quartieri_obj.get_quartiere_entities_life(id_quartiere);
   end get_quartiere_entities_life;

   function get_registro_quartieri return registro_quartieri is
   begin
      return cfg_quartieri_obj.get_registro_quartieri;
   end get_registro_quartieri;

   function get_gestore_bus_quartiere(id_quartiere: Positive) return ptr_rt_gestore_bus_quartiere is
   begin
      return cfg_quartieri_obj.get_quartiere_gestore_bus(id_quartiere);
   end get_gestore_bus_quartiere;

   function get_registro_gestori_bus_quartieri return registro_gestori_bus_quartieri is
   begin
      return cfg_quartieri_obj.get_registro_gestori_bus;
   end get_registro_gestori_bus_quartieri;

   function get_synchronizer_quartiere(id_quartiere: Positive) return ptr_rt_synchronization_partitions_type is
   begin
      return cfg_quartieri_obj.get_synchronizer_quartiere(id_quartiere);
   end get_synchronizer_quartiere;

end the_name_server;
