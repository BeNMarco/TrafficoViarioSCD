with Ada.Text_IO;

with strade_e_incroci_common;
with remote_types;

use Ada.Text_IO;

use strade_e_incroci_common;
use remote_types;

package body risorse_strade_e_incroci is

   protected body resource_segmento_strada is
      procedure prova is
      begin
      	Put_Line("backtohome");
      end prova;
   end resource_segmento_strada;

end risorse_strade_e_incroci;
