with remote_types;

use remote_types;

package risorse_strade_e_incroci is

   protected type resource_segmento_strada is new rt_segmento with
      procedure prova;
   private
      l: Positive:=1;
   end resource_segmento_strada;

   type ptr_resource_segmento_strada is access all resource_segmento_strada;
   type resource_segmenti_strade is array(Positive range <>) of ptr_resource_segmento_strada;
   type ptr_resource_segmenti_strade is access all resource_segmenti_strade;

end risorse_strade_e_incroci;
