with remote_types;

use remote_types;

package start_simulation is

   protected type quartiere_entities_life is new rt_quartiere_entities_life with
        procedure abitante_is_arrived(id_quartiere: Positive; id_abitante: Positive);
      procedure start_entity_to_move;
   end quartiere_entities_life;

end start_simulation;
