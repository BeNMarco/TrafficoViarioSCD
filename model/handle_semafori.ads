with remote_types;
with mailbox_risorse_attive;

use remote_types;
use mailbox_risorse_attive;

package handle_semafori is

   type handler_semafori_quartiere is tagged private;
   type ptr_handler_semafori_quartiere is access all handler_semafori_quartiere;

   procedure change_semafori(obj: handler_semafori_quartiere);

   procedure change_semafori_bipedi(obj: handler_semafori_quartiere);

   procedure set_num_delta_semafori(obj: in out handler_semafori_quartiere; num_delta: Natural);

   procedure set_id_turno(obj: in out handler_semafori_quartiere; num_turno: Positive);

   function get_id_turno(obj: handler_semafori_quartiere) return Positive;
   function get_num_delta_semafori(obj: handler_semafori_quartiere) return Natural;
private

   type handler_semafori_quartiere is tagged record
      id_turno: Positive:= 1; -- può essere 1 => cambio semaforo macchine ,2 => passano i bipedi,
      			      -- 3 => cambia semaforo macchine, 4 => passano i bipedi
      delta_semafori: Natural:= 0;
   end record;

end handle_semafori;
