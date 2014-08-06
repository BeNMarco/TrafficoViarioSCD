with remote_types;

use remote_types;

package risorse_strade_e_incroci is


   protected type resource_segmento_strada is new rt_segmento with
      procedure prova;
   private
      l: Positive:=1;
   end resource_segmento_strada;

   type ptr_resource_segmento_strada is access all resource_segmento_strada;

   type core_avanzamento is limited interface;

   procedure configure(entity: access core_avanzamento; id: Positive; resource: ptr_resource_segmento_strada) is abstract;

   task type core_avanzamento_urbane is new core_avanzamento with
      entry configure(id: Positive; resource: ptr_resource_segmento_strada);
   end core_avanzamento_urbane;

   type task_container_urbane is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_ingressi is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_rotonde is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_incroci is array(Positive range <>) of core_avanzamento_urbane;

   type resource_segmenti_strade is array(Positive range <>) of ptr_resource_segmento_strada;
   type ptr_resource_segmenti_strade is access all resource_segmenti_strade;

end risorse_strade_e_incroci;
