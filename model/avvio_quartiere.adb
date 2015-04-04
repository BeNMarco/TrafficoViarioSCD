with GNATCOLL.JSON;
with Ada.Text_IO;
with Polyorb.Parameters;
with Ada.Directories;
with Ada.Direct_IO;
with System.RPC;

with absolute_path;
with JSON_Helper;
with strade_e_incroci_common;
with the_name_server;
with remote_types;
with resource_map_inventory;
with risorse_strade_e_incroci;
with start_simulation;
with data_quartiere;
with risorse_mappa_utilities;
with mailbox_risorse_attive;
with risorse_passive_data;
with snapshot_interface;
with System_error;
with Ada.Calendar;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with synchronization_task_partition;

use GNATCOLL.JSON;
use Ada.Text_IO;

use absolute_path;
use JSON_Helper;
use strade_e_incroci_common;
use the_name_server;
use remote_types;
use resource_map_inventory;
use risorse_strade_e_incroci;
use start_simulation;
use data_quartiere;
use risorse_mappa_utilities;
use mailbox_risorse_attive;
use risorse_passive_data;
use snapshot_interface;
use System_error;
use Ada.Calendar;
use Ada.Exceptions;
use Ada.Strings.Unbounded;
use synchronization_task_partition;

package body avvio_quartiere is

   procedure init is
      json_quartiere: JSON_Value:= get_json_quartiere;
      array_elementi: JSON_Array;
      elemento: JSON_Value;
      can_quartiere_begin: Boolean:= False;
      error_state: Boolean:= False;
   begin

      configure_quartiere_obj;
      if log_system_error.is_in_error then
         configure_tasks;
         return;
      end if;

      configure_quartiere;
      if log_system_error.is_in_error then
         configure_tasks;
         return;
      end if;

      array_elementi:= json_quartiere.Get("strade_ingresso");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id",get_from_ingressi+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("incroci_a_4");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id",get_from_incroci_a_4+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("incroci_a_3");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id",get_from_incroci_a_3+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("luoghi");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_luogo",get_from_ingressi+i-1);
         elemento.Set_Field("idstrada",get_from_ingressi+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("pedoni");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_abitante",get_from_abitanti+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("auto");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_abitante",get_from_abitanti+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("bici");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_abitante",get_from_abitanti+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("abitanti");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_abitante",get_from_abitanti+i-1);
      end loop;

      array_elementi:= json_quartiere.Get("autobus");
      for i in 1..Length(array_elementi) loop
         elemento:= Get(array_elementi,i);
         elemento.Set_Field("id_autobus",get_to_abitanti-get_num_autobus+i);
      end loop;

      begin
         get_webServer.registra_mappa_quartiere(Write(json_quartiere,False),get_id_quartiere);
      exception
         when System.RPC.Communication_Error =>
            log_system_error.set_error(webserver,error_state);
         when others =>
            log_system_error.set_error(altro,error_state);
      end;

      -- prima di muovere le entità che effettuano delle chiamate ad altri
      -- quartieri si aspetta che vengono configurati
      if log_system_error.is_in_error=False then
         start_entity_to_move;
      end if;

      configure_tasks;
      if log_system_error.is_in_error=False then
         recovery_start_entity_to_move;
      end if;

   exception
      when System.RPC.Communication_Error =>
         log_system_error.set_error(altro,error_state);
         -- se i task sono in select statement li chiudo
         configure_tasks;
         Put_Line("partizione remota non raggiungibile.");
      when Error: others =>
         log_system_error.set_error(altro,error_state);
         -- se i task sono in select statement li chiudo
         configure_tasks;
         --log_system_error.set_message_error(To_Unbounded_String(Exception_Information(Error)));
         Put_Line(Exception_Information(Error));
   end init;

   task body watchdog is
      contatore: Natural:= 0;
      flag_errore: Boolean:= False;
      flag_to_updated: Boolean:= False;
   begin
      loop
         delay 2.0;
         --for i in 1..get_num_quartieri loop
         --   begin
         --      if get_ref_quartiere(i)/=null then
         --         if get_ref_quartiere(i).is_a_new_quartiere(1) then
         --            null;
         --         end if;
         --      end if;
         --   exception
         --      when others =>
         --         -- il nameserver non risponde quindi chiudo tutto
         --         log_system_error.set_error(altro,flag_to_updated);
         --         get_synchronization_partitions_object.exit_system;
         --         get_synchronization_tasks_partition_object.exit_system;
         --         for j in get_from_urbane..get_to_urbane loop
         --            get_urbane_segmento_resources(j).exit_system;
         --         end loop;
         --         flag_errore:= True;
         --   end;
         --end loop;
         if get_server_gps/=null and then get_server_gps.is_alive then
            null;
         end if;
         if get_webServer/=null and then get_webServer.is_alive then
            null;
         end if;
         exit when log_system_error.is_in_error
           or get_quartiere_utilities_obj.all_system_can_be_closed;
      end loop;

      recovery_status.wait_finish_work;
         -- qui si potrebbe ricostruire una snapshot del quartiere
         -- prima di chiuderlo effettivamente

      quartiere_has_finished_all_operations(get_id_quartiere);

   exception
      when others =>
         log_system_error.set_error(altro,flag_to_updated);
         get_synchronization_partitions_object.exit_system;
         get_synchronization_tasks_partition_object.exit_system;
         for j in get_from_urbane..get_to_urbane loop
            get_urbane_segmento_resources(j).exit_system;
         end loop;
   end watchdog;



end avvio_quartiere;
