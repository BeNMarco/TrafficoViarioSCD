with Text_IO;

with mailbox_risorse_attive;
with the_name_server;
with data_quartiere;

use Text_IO;

use mailbox_risorse_attive;
use the_name_server;
use data_quartiere;

package body handle_semafori is

  procedure set_num_delta_semafori(obj: in out handler_semafori_quartiere; num_delta: Natural) is
   begin
      obj.delta_semafori:= num_delta;
   end set_num_delta_semafori;

   procedure set_id_turno(obj: in out handler_semafori_quartiere; num_turno: Positive) is
   begin
      obj.id_turno:= num_turno;
   end set_id_turno;

   function get_id_turno(obj: handler_semafori_quartiere) return Positive is
   begin
      return obj.id_turno;
   end get_id_turno;

   function get_num_delta_semafori(obj: handler_semafori_quartiere) return Natural is
   begin
      return obj.delta_semafori;
   end get_num_delta_semafori;

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

   procedure change_semafori_bipedi(obj: handler_semafori_quartiere) is
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
            get_incroci_segmento_resources(i).change_semafori_pedoni;
         end loop;
      end if;

   end change_semafori_bipedi;


end handle_semafori;
