with remote_types;
with strade_e_incroci_common;
with global_data;

use remote_types;
use strade_e_incroci_common;
use global_data;

package configuration_cache_abitanti is
   pragma Remote_Call_Interface;

   procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                               bici: list_bici_quartiere; auto: list_auto_quartiere);

   procedure get_bound_quartieri(bounds: out bound_quartieri);

   procedure cache_quartiere_creata;

   function get_abitanti_quartieri return list_abitanti_temp;

   function get_pedoni_quartieri return list_pedoni_temp;

   function get_bici_quartieri return list_bici_temp;

   function get_auto_quartieri return list_auto_temp;

   function cfg_get_min_length_entità(entity: entità) return Float;

private

   protected type cache_abitanti is
      procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                                    bici: list_bici_quartiere; auto: list_auto_quartiere);
      procedure get_bound_quartieri(bounds: out bound_quartieri);
      procedure cache_quartiere_creata;

      -- metodi di get possono essere invocati in qualunque ordine
      -- purchè invocati una volta sola dai quartieri dato che avviene
      -- poi la deallocazione delle variabili temporanee della risorsa protetta
      function get_abitanti_quartieri return list_abitanti_temp;
      function get_pedoni_quartieri return list_pedoni_temp;
      function get_bici_quartieri return list_bici_temp;
      function get_auto_quartieri return list_auto_temp;
      function get_min_length_entità(entity: entità) return Float;
   private
      temp_abitanti: access list_abitanti_quartieri:= new list_abitanti_quartieri(1..get_num_quartieri);
      temp_pedoni: access list_pedoni_quartieri:= new list_pedoni_quartieri(1..get_num_quartieri);
      temp_bici: access list_bici_quartieri:= new list_bici_quartieri(1..get_num_quartieri);
      temp_auto: access list_auto_quartieri:= new list_auto_quartieri(1..get_num_quartieri);
      quartieri_registrati: Natural:= 0;
      min_from_abitanti: Natural:= Natural'Last;
      max_to_abitanti: Natural:= 0;
      abitanti_quartieri_registrati: Natural:= 0;
      min_length_pedoni: Float:= Float'Last;
      min_length_bici: Float:= Float'Last;
      min_length_auto: Float:= Float'Last;
   end cache_abitanti;

   server_cache_abitanti: cache_abitanti;

end configuration_cache_abitanti;
