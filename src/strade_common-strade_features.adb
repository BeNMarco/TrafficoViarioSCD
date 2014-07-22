with Ada.Text_IO;

with strade_common;
with rt_strade;

use Ada.Text_IO;

use strade_common;
use rt_strade;

package body strade_common.strade_features is

   protected body resource_segmento_strada is
      procedure prova is
      begin
      	Put_Line("backtohome");
      end prova;
   end resource_segmento_strada;

   function create_new_urbana(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                                val_lunghezza: Natural;val_num_corsie: Positive;
                                val_ptr_resource_strada: ptr_rt_segmento) return ptr_strada_urbana_features is
      ptr_strada: ptr_strada_urbana_features:= new strada_urbana_features;
   begin
      ptr_strada.id:= val_id;
      ptr_strada.tipo:= val_tipo;
      ptr_strada.id_quartiere:= val_id_quartiere;
      ptr_strada.lunghezza:= val_lunghezza;
      ptr_strada.num_corsie:= val_num_corsie;
      ptr_strada.ptr_resource_strada:= val_ptr_resource_strada;
      return ptr_strada;
   end create_new_urbana;


end strade_common.strade_features;
