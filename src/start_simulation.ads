with remote_types;

use remote_types;

package start_simulation is

   procedure start_entity_to_move;

   type quartiere_entities_life is new rt_quartiere_entities_life with null record;
   type ptr_quartiere_entities_life is access all quartiere_entities_life;

   procedure abitante_is_arrived(obj: quartiere_entities_life; id_abitante: Positive);

   function get_quartiere_entities_life_obj return ptr_quartiere_entities_life;

private

   quartiere_entities_life_obj: ptr_quartiere_entities_life:= new quartiere_entities_life;

end start_simulation;
