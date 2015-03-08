with remote_types;
with mailbox_risorse_attive;

use remote_types;
use mailbox_risorse_attive;

package handle_semafori is

   type handler_semafori_quartiere is new rt_handler_semafori_quartiere with null record;
   type ptr_handler_semafori_quartiere is access all handler_semafori_quartiere;

   procedure change_semafori(obj: handler_semafori_quartiere);

   procedure change_semafori_bipedi(obj: handler_semafori_quartiere);

end handle_semafori;
