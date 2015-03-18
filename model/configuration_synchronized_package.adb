with Ada.Text_IO;

with remote_types;
with the_name_server;

use Ada.Text_IO;

use remote_types;
use the_name_server;

package body configuration_synchronized_package is

   procedure registra_attesa_quartiere_obj(id_quartiere: Positive; wait_obj: ptr_rt_wait_all_quartieri) is
   begin
      synchronized_obj.registra_attesa_quartiere_obj(id_quartiere,wait_obj);
   end registra_attesa_quartiere_obj;

   procedure set_attesa_for_quartiere(id_quartiere: Positive) is
   begin
      synchronized_obj.set_attesa_for_quartiere(id_quartiere);
   end set_attesa_for_quartiere;

   function is_set_synchonized_obj return Boolean is
   begin
      if synchronized_obj/=null then
         return True;
      else
         return False;
      end if;
   end is_set_synchonized_obj;

   procedure configure_num_quartieri_synchronized_package(numero_quartieri: in Positive) is
   begin
      synchronized_obj:= new synchronized_quartieri_resource(numero_quartieri);
   end configure_num_quartieri_synchronized_package;

   protected body synchronized_quartieri_resource is

      procedure registra_attesa_quartiere_obj(id_quartiere: Positive; wait_object: ptr_rt_wait_all_quartieri) is
      begin
         wait_obj(id_quartiere):= wait_object;
      end registra_attesa_quartiere_obj;

      procedure set_attesa_for_quartiere(id_quartiere: Positive) is
      begin
         waiting_quartieri(id_quartiere):= True;
         if get_number_waiting_quartieri=numero_quartieri then
            for i in wait_obj'Range loop
               wait_obj(i).all_quartieri_set;
            end loop;
            waiting_quartieri:= (others => False);
         end if;
      end set_attesa_for_quartiere;

      function get_number_waiting_quartieri return Natural is
         counter: Natural:= 0;
      begin
         for i in waiting_quartieri'Range loop
            if waiting_quartieri(i) then
               counter:= counter+1;
            end if;
         end loop;
         return counter;
      end get_number_waiting_quartieri;

   end synchronized_quartieri_resource;

end configuration_synchronized_package;
