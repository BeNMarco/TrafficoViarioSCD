
package strade_common is
   pragma Pure;

   type rt_segmento is limited interface;

   type rt_strada_features is abstract tagged limited private;

   type type_strade is (urbana,ingresso);

   type rt_incroci_features(num_roads: Positive) is abstract tagged limited private;

   type list_roads is array(Positive range <>) of access rt_strada_features;

private

   type rt_strada_features is tagged limited record
      tipo: type_strade;
      id: Positive;
      id_quartiere: Positive;
      lunghezza: Natural;
      num_corsie: Positive;
      ptr_resource_strada: access rt_segmento;
   end record;

   type rt_incroci_features(num_roads: Positive) is tagged limited record
      roads:list_roads(1..num_roads);
      ptr_resource_incrocio: access rt_segmento;
   end record;

end strade_common;
