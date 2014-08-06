with Ada.Text_IO;

with strade_e_incroci_common;
with remote_types;

use Ada.Text_IO;

use strade_e_incroci_common;
use remote_types;

package body risorse_strade_e_incroci is

   task body core_avanzamento_urbane is
      id_task: Positive;--mail_box: ptr_resource_segmento_strada:= resource;
      mailbox: ptr_resource_segmento_strada;
   begin
      accept configure(id: Positive; resource: ptr_resource_segmento_strada) do
         id_task:= id;
         mailbox:= resource;
      end configure;
      Put_Line(Positive'Image(id_task));
   end core_avanzamento_urbane;

   protected body resource_segmento_strada is
      procedure prova is
      begin
      	Put_Line("backtohome");
      end prova;
   end resource_segmento_strada;

end risorse_strade_e_incroci;
