
package rt_strade is
   pragma Remote_Types;

   type rt_segmento is limited interface;

   type rt_strada_features is abstract tagged limited private;

   type ptr_rt_strada_features is access all rt_strada_features'Class;

   type type_strade is (urbana,ingresso);

   type ptr_rt_segmento is access all rt_segmento'Class;

   type rt_incroci_features(num_roads: Positive) is abstract tagged limited private;

   type ptr_rt_incroci_features is access all rt_incroci_features'Class;

   type list_roads is array(Positive range <>) of ptr_rt_strada_features;

private

   type rt_strada_features is tagged limited record
      tipo: type_strade;
      id: Positive;
      id_quartiere: Positive;
      lunghezza: Natural;
      num_corsie: Positive;
      ptr_resource_strada: ptr_rt_segmento;
   end record;

   type rt_incroci_features(num_roads: Positive) is tagged limited record
      roads:list_roads(1..num_roads);
      ptr_resource_incrocio: ptr_rt_segmento;
   end record;

end rt_strade;
