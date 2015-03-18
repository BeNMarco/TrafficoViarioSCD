with remote_types;
--with global_data;

use remote_types;
--use global_data;

package configuration_synchronized_package is
   pragma Remote_Call_Interface;

   procedure registra_attesa_quartiere_obj(id_quartiere:Positive; wait_obj: ptr_rt_wait_all_quartieri);

   procedure set_attesa_for_quartiere(id_quartiere: Positive);

   type wait_obj_quartieri is array(Positive range <>) of ptr_rt_wait_all_quartieri;
   type quartieri_in_wait is array(Positive range <>) of Boolean;

   function is_set_synchonized_obj return Boolean;

   procedure configure_num_quartieri_synchronized_package(numero_quartieri: in Positive);

private

   protected type synchronized_quartieri_resource(numero_quartieri: Positive) is
      procedure registra_attesa_quartiere_obj(id_quartiere:Positive; wait_object: ptr_rt_wait_all_quartieri);
      procedure set_attesa_for_quartiere(id_quartiere: Positive);
      function get_number_waiting_quartieri return Natural;
   private
      wait_obj: wait_obj_quartieri(1..numero_quartieri):= (others => null);
      waiting_quartieri: quartieri_in_wait(1..numero_quartieri):= (others => False);
   end synchronized_quartieri_resource;

   type ptr_synchronized_quartieri_resource is access synchronized_quartieri_resource;

   synchronized_obj: ptr_synchronized_quartieri_resource;

end configuration_synchronized_package;
