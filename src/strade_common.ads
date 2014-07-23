
package strade_common is
   pragma Pure;

   type rt_segmento is limited interface;

   type rt_strada_features is abstract tagged private;

   type type_strade is (urbana,ingresso);

   type road_incrocio_features is tagged private;

   -- begin tipi incroci
   type list_road_incrocio_a_4 is array(Positive range 1..4) of road_incrocio_features;
   type list_road_incrocio_a_3 is array(Positive range 1..3) of road_incrocio_features;
   type list_road_incrocio_a_2 is array(Positive range 1..2) of road_incrocio_features;
   -- end tipo incroci

   function create_new_road_incrocio(val_id_quartiere: Positive;val_id_strada: Positive;
                                     val_tipo_strada: type_strade) return road_incrocio_features;

private

   type rt_strada_features is tagged record
      tipo: type_strade;
      id: Positive;  -- id strada coincide con id della sua risorsa protetta
      id_quartiere: Positive;
      lunghezza: Natural;
      num_corsie: Positive;
   end record;

   type road_incrocio_features is tagged record
      id_quartiere: Positive;
      id_strada: Positive;
      tipo_strada: type_strade;
   end record;

end strade_common;
