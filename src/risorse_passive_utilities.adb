with strade_e_incroci_common;
with data_quartiere;

use strade_e_incroci_common;
use data_quartiere;

package body risorse_passive_utilities is
   pragma Warnings(off);
   function create_array_abitanti return list_abitanti is
   	d: list_abitanti(1..2,2..4);
   begin
      return d;
   end create_array_abitanti;
   function create_array_pedoni return list_pedoni is
   	d: list_pedoni(1..2,2..4);
   begin
      return d;
   end create_array_pedoni;
   function create_array_bici return list_bici is
   	d: list_bici(1..2,2..4);
   begin
      return d;
   end create_array_bici;
   function create_array_auto return list_auto is
   	d: list_auto(1..2,2..4);
   begin
      return d;
   end create_array_auto;

end risorse_passive_utilities;
