with remote_types;

use remote_types;

package start_simulation is

   fermata_inesistente: exception;

   procedure start_entity_to_move;

   procedure recovery_start_entity_to_move;

   protected recovery_status is
      entry wait_finish_work;
      procedure work_is_finished;
   private
      finish_recovery: Boolean:= False;
   end recovery_status;

private
   procedure start_autobus_to_move;

end start_simulation;
