with Text_IO;

with mailbox_risorse_attive;
with the_name_server;
with data_quartiere;

use Text_IO;

use mailbox_risorse_attive;
use the_name_server;
use data_quartiere;

package body handle_semafori is

   procedure change_semafori(obj: handler_semafori_quartiere) is
      from: Natural;
      to: Natural;
   begin
      if get_from_incroci_a_4/=0 then
         from:= get_from_incroci_a_4;
      elsif get_from_incroci_a_3/=0 then
         from:= get_from_incroci_a_3;
      end if;

      if get_to_incroci_a_3/=0 then
         to:= get_to_incroci_a_3;
      elsif get_to_incroci_a_4/=0 then
         to:= get_to_incroci_a_4;
      end if;

      if from/=0 then
         for i in from..to loop
            get_incroci_segmento_resources(i).change_verso_semafori_verdi;
         end loop;
      end if;

   end change_semafori;

end handle_semafori;
