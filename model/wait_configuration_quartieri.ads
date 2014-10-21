with remote_types;

use remote_types;

package wait_configuration_quartieri is

   protected type wait_all_quartieri is new rt_wait_all_quartieri with
      procedure all_quartieri_set;
      entry wait_quartieri;
   private
      segnale: Boolean:= False;
   end wait_all_quartieri;

   type ptr_wait_all_quartieri is access wait_all_quartieri'Class;

end wait_configuration_quartieri;
