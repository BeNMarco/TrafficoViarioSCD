with remote_types;
with global_data;

use remote_types;
use global_data;

package configuration_synchronized_package is
   pragma Remote_Call_Interface;

   procedure registra_attesa_quartiere_obj(id_quartiere:Positive; wait_obj: ptr_rt_wait_all_quartieri);

   procedure set_attesa_for_quartiere(id_quartiere: Positive);

private

   type wait_obj_quartieri is array(1..global_data.num_quartieri) of ptr_rt_wait_all_quartieri;
   type quartieri_in_wait is array(1..global_data.num_quartieri) of Boolean;

   protected type synchronized_quartieri_resource is
      procedure registra_attesa_quartiere_obj(id_quartiere:Positive; wait_object: ptr_rt_wait_all_quartieri);
      procedure set_attesa_for_quartiere(id_quartiere: Positive);
      function get_number_waiting_quartieri return Natural;
   private
      wait_obj: wait_obj_quartieri:= (others => null);
      waiting_quartieri: quartieri_in_wait:= (others => False);
   end synchronized_quartieri_resource;

   synchronized_obj: synchronized_quartieri_resource;

end configuration_synchronized_package;
